%% Código para combinar bandas, generar composiciones e índices por fecha
% Este script recorre las subcarpetas dentro de "Fotos_T", carga las imágenes
% correspondientes a cada fecha, realiza el preprocesamiento, genera las composiciones 
% (True Color, False Color y SWIR) y calcula los índices NDVI, NDMI y SWIR Index.
% Los resultados se muestran en una misma figura en forma de subplots.

%% 1. Definir la ruta principal y las subcarpetas (fechas)
rutaPrincipal = 'Fotos_T';
subcarpetas = {'21-06-2017', '26-06-2017', '31-03-2025'};

%% 2. Procesar cada subcarpeta
for idx = 1:length(subcarpetas)
    carpetaFecha = fullfile(rutaPrincipal, subcarpetas{idx});
    fprintf('Procesando la carpeta: %s\n', carpetaFecha);
    
    % Cargar las bandas desde la subcarpeta actual
    try
        B2   = imread(fullfile(carpetaFecha, 'B02.png'));   % Azul
        B3   = imread(fullfile(carpetaFecha, 'B03.png'));   % Verde
        B4   = imread(fullfile(carpetaFecha, 'B04.png'));   % Rojo
        B8   = imread(fullfile(carpetaFecha, 'B08.png'));   % NIR
        B8A  = imread(fullfile(carpetaFecha, 'B08A.png'));  % NIR estrecho
        B11  = imread(fullfile(carpetaFecha, 'B11.png'));    % SWIR1
        B12  = imread(fullfile(carpetaFecha, 'B12.png'));    % SWIR2
        disp('Imágenes cargadas correctamente');
    catch ME
        fprintf('Error al cargar imágenes en %s:\n%s\n', carpetaFecha, ME.message);
        continue; % Salta a la siguiente subcarpeta si hay error
    end
    
    %% 3. Preprocesamiento: Asegurar que todas las bandas tengan el mismo tamaño
    % Se toma como referencia la dimensión de B4
    [filas, columnas, ~] = size(B4);
    B2   = imresize(B2,  [filas, columnas]);
    B3   = imresize(B3,  [filas, columnas]);
    B4   = imresize(B4,  [filas, columnas]);
    B8   = imresize(B8,  [filas, columnas]);
    B8A  = imresize(B8A, [filas, columnas]);
    B11  = imresize(B11, [filas, columnas]);
    B12  = imresize(B12, [filas, columnas]);
    
    %% 4. Conversión a escala de grises si las imágenes son RGB
    if size(B2, 3) > 1,   B2 = rgb2gray(B2); end
    if size(B3, 3) > 1,   B3 = rgb2gray(B3); end
    if size(B4, 3) > 1,   B4 = rgb2gray(B4); end
    if size(B8, 3) > 1,   B8 = rgb2gray(B8); end
    if size(B8A, 3) > 1,  B8A = rgb2gray(B8A); end
    if size(B11, 3) > 1,  B11 = rgb2gray(B11); end
    if size(B12, 3) > 1,  B12 = rgb2gray(B12); end
    
    %% 5. Normalización de las bandas para los cálculos (escala [0,1])
    B2_norm   = double(B2)  / double(max(B2(:)));
    B3_norm   = double(B3)  / double(max(B3(:)));
    B4_norm   = double(B4)  / double(max(B4(:)));
    B8_norm   = double(B8)  / double(max(B8(:)));
    B8A_norm  = double(B8A) / double(max(B8A(:)));
    B11_norm  = double(B11) / double(max(B11(:)));
    B12_norm  = double(B12) / double(max(B12(:)));
    
    %% 6. Generar imágenes de visualización aplicando tail clipping a B2, B3 y B4
    % Se aplica imadjust a las bandas B2, B3 y B4 para mapear el rango [0,100] a [0,1]
    % (suponiendo imágenes de 8 bits, 100/255 ~ 0.392)
    B2_disp = imadjust(im2double(B2), [0 100/255], []);
    B3_disp = imadjust(im2double(B3), [0 100/255], []);
    B4_disp = imadjust(im2double(B4), [0 100/255], []);
    
    %% 7. Composiciones Espectrales
    % 7.1. Composición True Color (RGB): R <- B4, G <- B3, B2 <- B2 (usando tail clipping)
    trueColor = cat(3, B4_disp, B3_disp, B2_disp);
    
    % 7.2. Composición False Color (NIR): R <- B8 (normal), G <- B4, B: <- B3 (usando tail clipping en B4 y B3)
    falseColor = cat(3, B8_norm, B4_disp, B3_disp);
    
    % 7.3. Composición SWIR: R <- B12, G <- B11, B <- B8 (se usa la normalización original)
    SWIR_comp = cat(3, B12_norm, B11_norm, B8_norm);
    
    %% 8. Cálculo de Índices (utilizando la normalización original)
    % 8.1. NDVI: (B8 - B4) / (B8 + B4)
    NDVI = (B8_norm - B4_norm) ./ (B8_norm + B4_norm);
    NDVI(isnan(NDVI)) = 0;
    
    % 8.2. NDMI (Moisture Index): (B8A - B11) / (B8A + B11)
    NDMI = (B8A_norm - B11_norm) ./ (B8A_norm + B11_norm);
    NDMI(isnan(NDMI)) = 0;
    
    % 8.3. SWIR Index: (B12 - (B8A+B4)/2) / (B12 + (B8A+B4)/2)
    SWIR_index = (B12_norm - ((B8A_norm + B4_norm)/2)) ./ (B12_norm + ((B8A_norm + B4_norm)/2));
    SWIR_index(isnan(SWIR_index)) = 0;
    
    %% 9. Visualización conjunta en una sola figura (subplots)
    figure('Name', ['Resultados - ' subcarpetas{idx}]);
    
    % Subplot 1: True Color
    subplot(2,3,1);
    imshow(trueColor);
    title('True Color (RGB)');
    
    % Subplot 2: False Color
    subplot(2,3,2);
    imshow(falseColor);
    title('False Color (NIR)');
    
    % Subplot 3: NDVI
    subplot(2,3,3);
    imagesc(NDVI);
    colormap('jet'); colorbar;
    title('NDVI');
    caxis([-1 1]);
    
    % Subplot 4: NDMI (Moisture Index)
    subplot(2,3,4);
    imagesc(NDMI);
    colormap('jet'); colorbar;
    title('NDMI');
    caxis([-1 1]);
    
    % Subplot 5: SWIR Index
    subplot(2,3,5);
    imagesc(SWIR_index);
    colormap('jet'); colorbar;
    title('SWIR Index');
    caxis([-1 1]);
    
    % Subplot 6: Composición SWIR
    subplot(2,3,6);
    imshow(SWIR_comp);
    title('Composición SWIR');
    
    drawnow;
end

%% Función adicional: Crear composición RGB personalizada (si es necesario)
function crearComposicionRGB(R, G, B, nombre, ruta)
    % Normalizar las bandas
    R_norm = double(R) / double(max(R(:)));
    G_norm = double(G) / double(max(G(:)));
    B_norm = double(B) / double(max(B(:)));
    
    % Crear la composición RGB
    RGB = cat(3, R_norm, G_norm, B_norm);
    
    % Mostrar la composición
    figure('Name', ['Composición ' nombre]);
    imshow(RGB);
    title(['Composición ' nombre]);
    
    % Guardar la composición en formato PNG (descomentar si se desea guardar)
    % imwrite(RGB, fullfile(ruta, [nombre '.png']));
end