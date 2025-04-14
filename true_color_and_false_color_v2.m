%% Script para generar True Color y False Color
% Se procesan las imágenes contenidas en las subcarpetas de "Fotos_T".  
% Para cada fecha se generan las composiciones visuales aplicando:
%   - True Color (RGB): R ← B04, G ← B03, B ← B02 (corte de cola [0,100])
%   - False Color (NIR): R ← B08 (corte de cola [0,125]), G ← B04 y B ← B03 (corte de cola [0,100])
%
% Los cortes de cola se han decidido con base en las estadísticas obtenidas.

%% 1. Definir la ruta principal y las subcarpetas (fechas)
rutaPrincipal = 'Fotos_T';
subcarpetas = {
    '21-06-2017', ...
    '21-06-2019', ...
    '24-06-2024', ...
    '26-06-2017', ...
    '26-06-2018', ...
    '30-06-2020', ...
    '30-06-2021', ...
    '30-06-2022', ...
    '30-06-2023', ...
    '31-03-2025'
};

%% 2. Procesar cada subcarpeta
for idx = 1:length(subcarpetas)
    carpetaFecha = fullfile(rutaPrincipal, subcarpetas{idx});
    fprintf('Procesando la carpeta: %s\n', carpetaFecha);
    
    % Cargar las imágenes (se asume que están nombradas exactamente)
    try
        B2 = imread(fullfile(carpetaFecha, 'B02.png'));   % Azul
        B3 = imread(fullfile(carpetaFecha, 'B03.png'));   % Verde
        B4 = imread(fullfile(carpetaFecha, 'B04.png'));   % Rojo
        B8 = imread(fullfile(carpetaFecha, 'B08.png'));   % NIR
    catch ME
        fprintf('Error al cargar imágenes en %s:\n%s\n', carpetaFecha, ME.message);
        continue;
    end
    
    % (Opcional) Redimensionar para que todas tengan el mismo tamaño, usando por ejemplo el tamaño de B4.
    [filas, columnas, ~] = size(B4);
    B2 = imresize(B2, [filas, columnas]);
    B3 = imresize(B3, [filas, columnas]);
    B4 = imresize(B4, [filas, columnas]);
    B8 = imresize(B8, [filas, columnas]);
    
    % Si las imágenes son RGB, convertirlas a escala de grises (ya que se espera la banda)
    if size(B2,3) > 1, B2 = rgb2gray(B2); end
    if size(B3,3) > 1, B3 = rgb2gray(B3); end
    if size(B4,3) > 1, B4 = rgb2gray(B4); end
    if size(B8,3) > 1, B8 = rgb2gray(B8); end

    %% 3. Para visualización, aplicar corte de cola a las bandas
    % Para True Color: cortes [0,100] para las bandas B02, B03 y B04
    B2_disp = imadjust(im2double(B2), [0 100/255], []);
    B3_disp = imadjust(im2double(B3), [0 100/255], []);
    B4_disp = imadjust(im2double(B4), [0 100/255], []);
    trueColor = cat(3, B4_disp, B3_disp, B2_disp); % R: B4, G: B3, B: B2
    
    % Para False Color: 
    % Para B8 se aplica corte [0,125] y para B04 y B03 se mantienen corte [0,100]
    B8_disp = imadjust(im2double(B8), [0 125/255], []);
    falseColor = cat(3, B8_disp, B4_disp, B3_disp); % R: B8, G: B4, B: B3
    
    %% 4. Visualización en una figura (subplots)
    figure('Name', ['Composiciones - ' subcarpetas{idx}], 'NumberTitle', 'off');
    
    % Subplot 1: True Color
    subplot(1,2,1);
    imshow(trueColor);
    title(['True Color - ' subcarpetas{idx}]);
    
    % Subplot 2: False Color
    subplot(1,2,2);
    imshow(falseColor);
    title(['False Color - ' subcarpetas{idx}]);
    
    drawnow;
end