%% Script para calcular y visualizar NDVI, NDMI y SWIR Composite con color ramps personalizados
% Se procesan las imágenes en las subcarpetas de "Fotos_T".
% Para cada fecha se calculan:
%   - NDVI = (B08 - B04) / (B08 + B04)
%   - NDMI = (B08A - B11) / (B08A + B11)
% Y se genera la visualización SWIR como:
%   SWIR = cat(3, 2.5*B12, 2.5*B08A, 2.5*B04), con clip de valores a 1.
%
% Se utilizan dos color ramps personalizados (similares a los de Copernicus):
%   * Para NDVI: ramp_ndvi_values y ramp_ndvi_hex.
%   * Para NDMI: ramp_moisture_values y ramp_moisture_hex.
%
% Los índices se calculan usando los datos normalizados sin cortes, 
% y para la visualización se aplica un mapeo a RGB utilizando el colormap
% interpolado.
%
% MODIFICACIÓN: Ahora las imágenes NDVI también se guardan en alta resolución
% en una carpeta separada llamada "NDVIs"

%% 1. Definir la ruta principal y la lista de subcarpetas (fechas)
rutaPrincipal = 'Fotos_T';
subcarpetas = { '21-06-2017', '21-06-2019', '24-06-2024', '26-06-2017', ...
                '26-06-2018', '30-06-2020', '30-06-2021', '30-06-2022', ...
                '30-06-2023', '31-03-2025'};

% Crear carpeta para guardar los NDVIs si no existe
carpetaDestino = 'NDVIs';
if ~exist(carpetaDestino, 'dir')
    mkdir(carpetaDestino);
    fprintf('Se ha creado la carpeta %s para guardar las imágenes NDVI\n', carpetaDestino);
end

%% 2. Función auxiliar: hex2rgb
% Convierte un valor hexadecimal numérico (e.g., 0x0c0c0c) en un vector RGB [r,g,b] normalizado a [0,1].
function rgb = hex2rgb(hexVal)
    % Convertir el valor numérico a cadena con formato "#RRGGBB"
    s = sprintf('#%06X', hexVal);
    % Extraer los componentes y convertir a decimal normalizado
    r = hex2dec(s(2:3)) / 255;
    g = hex2dec(s(4:5)) / 255;
    b = hex2dec(s(6:7)) / 255;
    rgb = [r, g, b];
end

%% 3. Función auxiliar: generateColormap
% Esta función interpola un colormap a N colores, usando valores de entrada (ramp_values)
% y los colores correspondientes en hexadecimal (ramp_hex) dado el rango x_range.
function cmap = generateColormap(ramp_values, ramp_hex, N, x_range)
    nPoints = length(ramp_values);
    ramp_rgb = zeros(nPoints, 3);
    for i = 1:nPoints
        ramp_rgb(i,:) = hex2rgb(ramp_hex(i));
    end
    % Crear el vector de consulta
    xq = linspace(x_range(1), x_range(2), N);
    r_interp = interp1(ramp_values, ramp_rgb(:,1), xq, 'linear', 'extrap');
    g_interp = interp1(ramp_values, ramp_rgb(:,2), xq, 'linear', 'extrap');
    b_interp = interp1(ramp_values, ramp_rgb(:,3), xq, 'linear', 'extrap');
    cmap = [r_interp(:), g_interp(:), b_interp(:)];
end

%% 4. Definir los ramps para NDVI y Moisture Index (NDMI)
% Ramp para NDVI (según Copernicus)
ramp_ndvi_values = [-0.5, -0.2, -0.1, 0, 0.025, 0.05, 0.075, 0.1, 0.125, 0.15, 0.175, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 1];
ramp_ndvi_hex = [...
    0x0c0c0c; 0xbfbfbf; 0xdbdbdb; 0xeaeaea; 0xfff9cc; 0xede8b5; 0xddd89b; ...
    0xccc682; 0xbcb76b; 0xafc160; 0xa3cc59; 0x91bf51; 0x7fb247; 0x70a33f; ...
    0x609635; 0x4f892d; 0x3f7c23; 0x306d1c; 0x216011; 0x0f540a; 0x004400];

% Ramp para Moisture (NDMI)
ramp_moisture_values = [-0.8, -0.24, -0.032, 0.032, 0.24, 0.8];
ramp_moisture_hex = [...
    0x800000; 0xff0000; 0xffff00; 0x00ffff; 0x0000ff; 0x000080];

% Generar los colormaps (256 colores para visualización):
cmap_ndvi = generateColormap(ramp_ndvi_values, ramp_ndvi_hex, 256, [-0.5, 1]);
cmap_moisture = generateColormap(ramp_moisture_values, ramp_moisture_hex, 256, [-0.8, 0.8]);

% Generar colormap NDVI de alta resolución para guardar imágenes (1024 colores):
cmap_ndvi_hires = generateColormap(ramp_ndvi_values, ramp_ndvi_hex, 1024, [-0.5, 1]);

%% 5. Procesar cada subcarpeta (cada fecha)
for idx = 1:length(subcarpetas)
    carpetaFecha = fullfile(rutaPrincipal, subcarpetas{idx});
    fprintf('Procesando la carpeta: %s\n', carpetaFecha);
    
    % Definir rutas de las bandas: B02, B03, B04, B08, B08A, B11, B12
    archivos = {'B02.png', 'B03.png', 'B04.png', 'B08.png', 'B08A.png', 'B11.png', 'B12.png'};
    try
        B02 = imread(fullfile(carpetaFecha, archivos{1}));
        B03 = imread(fullfile(carpetaFecha, archivos{2}));
        B04 = imread(fullfile(carpetaFecha, archivos{3}));
        B08 = imread(fullfile(carpetaFecha, archivos{4}));
        B08A = imread(fullfile(carpetaFecha, archivos{5}));
        B11 = imread(fullfile(carpetaFecha, archivos{6}));
        B12 = imread(fullfile(carpetaFecha, archivos{7}));
    catch ME
        fprintf('Error al cargar imágenes en %s:\n%s\n', carpetaFecha, ME.message);
        continue;
    end
    
    % Redimensionar todas al mismo tamaño (referencia: B04)
    [filas, columnas, ~] = size(B04);
    B02 = imresize(B02, [filas, columnas]);
    B03 = imresize(B03, [filas, columnas]);
    B04 = imresize(B04, [filas, columnas]);
    B08 = imresize(B08, [filas, columnas]);
    B08A = imresize(B08A, [filas, columnas]);
    B11 = imresize(B11, [filas, columnas]);
    B12 = imresize(B12, [filas, columnas]);
    
    % Convertir a escala de grises si es necesario
    if size(B02,3)>1, B02 = rgb2gray(B02); end
    if size(B03,3)>1, B03 = rgb2gray(B03); end
    if size(B04,3)>1, B04 = rgb2gray(B04); end
    if size(B08,3)>1, B08 = rgb2gray(B08); end
    if size(B08A,3)>1, B08A = rgb2gray(B08A); end
    if size(B11,3)>1, B11 = rgb2gray(B11); end
    if size(B12,3)>1, B12 = rgb2gray(B12); end
    
    % Normalizar a [0,1] para cálculos (datos originales sin recorte)
    B02_norm = im2double(B02);
    B03_norm = im2double(B03);
    B04_norm = im2double(B04);
    B08_norm = im2double(B08);
    B08A_norm = im2double(B08A);
    B11_norm = im2double(B11);
    B12_norm = im2double(B12);
    
    %% 6. Calcular índices
    % NDVI = (B08 - B04) / (B08 + B04)
    NDVI = (B08_norm - B04_norm) ./ (B08_norm + B04_norm);
    NDVI(isnan(NDVI)) = 0;
    
    % NDMI = (B08A - B11) / (B08A + B11)
    NDMI = (B08A_norm - B11_norm) ./ (B08A_norm + B11_norm);
    NDMI(isnan(NDMI)) = 0;
    
    % SWIR Composite: según Copernicus, multiplicar por 2.5 las bandas
    SWIR_comp = cat(3, 2.5*B12_norm, 2.5*B08A_norm, 2.5*B04_norm);
    SWIR_comp(SWIR_comp > 1) = 1;
    
    %% 7. Generar visualizaciones utilizando los color ramps
    % Para NDVI: escalar NDVI a [0,1] a partir del rango [-0.5, 1]
    NDVI_img = mat2gray(NDVI, [-0.5, 1]);
    NDVI_index = gray2ind(NDVI_img, 256);
    NDVI_rgb = ind2rgb(NDVI_index, cmap_ndvi);
    
    % Para NDMI: escalar NDMI a [0,1] a partir del rango [-0.8, 0.8]
    NDMI_img = mat2gray(NDMI, [-0.8, 0.8]);
    NDMI_index = gray2ind(NDMI_img, 256);
    NDMI_rgb = ind2rgb(NDMI_index, cmap_moisture);
    
    %% 8. Visualización final: Crear figura con 3 subplots
    figure('Name', ['Índices - ' subcarpetas{idx}], 'NumberTitle', 'off');
    
    % Subplot 1: NDVI
    subplot(1,3,1);
    imshow(NDVI_rgb);
    title(['NDVI - ' subcarpetas{idx}]);
    
    % Subplot 2: NDMI (Moisture Index)
    subplot(1,3,2);
    imshow(NDMI_rgb);
    title(['Moisture Index - ' subcarpetas{idx}]);
    
    % Subplot 3: SWIR Composite
    subplot(1,3,3);
    imshow(SWIR_comp);
    title(['SWIR Composite - ' subcarpetas{idx}]);
    
    drawnow;
    
    %% 9. NUEVO: Guardar imagen NDVI en alta resolución en la carpeta NDVIs
    % Generar una versión de alta resolución del NDVI
    NDVI_hires_index = gray2ind(NDVI_img, 1024); % Mayor resolución de color
    NDVI_hires_rgb = ind2rgb(NDVI_hires_index, cmap_ndvi_hires);
    
    % Convertir a formato uint8 para guardar como PNG
    NDVI_hires_rgb_8bit = im2uint8(NDVI_hires_rgb);
    
    % Definir el nombre del archivo de salida
    nombreArchivo = sprintf('NDVI_%s.png', subcarpetas{idx});
    rutaArchivo = fullfile(carpetaDestino, nombreArchivo);
    
    % Guardar la imagen NDVI en formato PNG (sin especificar Quality que es solo para JPEG)
    imwrite(NDVI_hires_rgb_8bit, rutaArchivo, 'PNG');
    fprintf('NDVI guardado en alta resolución: %s\n', rutaArchivo);
    
    % También guardar archivo de datos en formato .mat para análisis posteriores
    rutaMatFile = fullfile(carpetaDestino, sprintf('NDVI_data_%s.mat', subcarpetas{idx}));
    save(rutaMatFile, 'NDVI');
    fprintf('Datos brutos NDVI guardados en: %s\n', rutaMatFile);
end

fprintf('Proceso completado. Las imágenes NDVI se han guardado en la carpeta %s\n', carpetaDestino);