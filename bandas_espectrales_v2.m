%% Script para combinar bandas, generar composiciones e índices por fecha
% Se cargan las imágenes de cada fecha (subcarpeta en "Fotos_T"), se realiza el
% preprocesamiento, se calculan los índices (NDVI, NDMI y SWIR Index) y se crean
% las composiciones visuales aplicando cortes de cola específicos para cada banda:
%
% Parámetros de corte de cola (en imágenes de 8 bits):
% - B02, B03, B04: [0, 100]
% - B08, B08A, B12: [0, 125]
% - B11: [0, 150]
%
% Composiciones:
%   - True Color (RGB): R ← B4, G ← B3, B ← B2 (usando corte de cola [0,100])
%   - False Color (NIR): R ← B8 (corte [0,125]), G ← B4 y B ← B3 (corte [0,100])
%   - SWIR Composition: R ← B12 (corte [0,125]), G ← B11 (corte [0,150]), B ← B8 (corte [0,125])
%
% Se muestran en una figura con 6 subplots.

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
    [filas, columnas, ~] = size(B4);
    B2   = imresize(B2,  [filas, columnas]);
    B3   = imresize(B3,  [filas, columnas]);
    B4   = imresize(B4,  [filas, columnas]);
    B8   = imresize(B8,  [filas, columnas]);
    B8A  = imresize(B8A, [filas, columnas]);
    B11  = imresize(B11, [filas, columnas]);
    B12  = imresize(B12, [filas, columnas]);
    
    %% 4. Conversión a escala de grises si las imágenes son RGB
    if size(B2,3) > 1, B2 = rgb2gray(B2); end
    if size(B3,3) > 1, B3 = rgb2gray(B3); end
    if size(B4,3) > 1, B4 = rgb2gray(B4); end
    if size(B8,3) > 1, B8 = rgb2gray(B8); end
    if size(B8A,3) > 1, B8A = rgb2gray(B8A); end
    if size(B11,3) > 1, B11 = rgb2gray(B11); end
    if size(B12,3) > 1, B12 = rgb2gray(B12); end
    
    %% 5. Normalización para cálculos (sin corte de cola)
    B2_norm   = im2double(B2);
    B3_norm   = im2double(B3);
    B4_norm   = im2double(B4);
    B8_norm   = im2double(B8);
    B8A_norm  = im2double(B8A);
    B11_norm  = im2double(B11);
    B12_norm  = im2double(B12);
    
    %% 6. Calcular índices
    NDVI = (B8_norm - B4_norm) ./ (B8_norm + B4_norm);
    NDVI(isnan(NDVI)) = 0;
    
    NDMI = (B8A_norm - B11_norm) ./ (B8A_norm + B11_norm);
    NDMI(isnan(NDMI)) = 0;
    
    SWIR_index = (B12_norm - ((B8A_norm + B4_norm)/2)) ./ (B12_norm + ((B8A_norm + B4_norm)/2));
    SWIR_index(isnan(SWIR_index)) = 0;
    
    %% 7. Crear composiciones para visualización aplicando los cortes de cola
    % Para True Color: B2, B3, B4 con corte [0,100/255]
    B2_disp = imadjust(im2double(B2), [0 100/255], []);
    B3_disp = imadjust(im2double(B3), [0 100/255], []);
    B4_disp = imadjust(im2double(B4), [0 100/255], []);
    trueColor = cat(3, B4_disp, B3_disp, B2_disp);  % R: B4, G: B3, B: B2
    
    % Para False Color: R: B8 con corte [0,125/255], G: B4 y B: B3 con corte [0,100/255]
    B8_disp = imadjust(im2double(B8), [0 125/255], []);
    falseColor = cat(3, B8_disp, B4_disp, B3_disp);
    
    % Para SWIR Composition: R: B12 con corte [0,125/255], G: B11 con corte [0,150/255], B: B8 con corte [0,125/255]
    B12_disp = imadjust(im2double(B12), [0 125/255], []);
    B11_disp = imadjust(im2double(B11), [0 150/255], []);
    B8_disp_s = imadjust(im2double(B8), [0 125/255], []);
    SWIR_comp = cat(3, B12_disp, B11_disp, B8_disp_s);
    
    %% 8. Visualización conjunta en una sola figura (subplots)
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
    
    % Subplot 4: NDMI
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
    
    % Subplot 6: SWIR Composition
    subplot(2,3,6);
    imshow(SWIR_comp);
    title('Composición SWIR');
    
    drawnow;
end