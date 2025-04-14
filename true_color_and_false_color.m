% Script para generar composiciones de color verdadero y color falso
% a partir de las bandas en cada subcarpeta dentro de la carpeta "Fotos_T".

% Ruta principal
rutaPrincipal = 'Fotos_T';

% Subcarpetas a procesar (ajusta los nombres de acuerdo a tu estructura)
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

for i = 1:length(subcarpetas)
    % Construir la ruta de la subcarpeta
    rutaSubcarpeta = fullfile(rutaPrincipal, subcarpetas{i});
    
    %% Composición de Color Verdadero
    % Se requiere: B02.png (Azul), B03.png (Verde) y B04.png (Rojo)
    archivoB02 = fullfile(rutaSubcarpeta, 'B02.png');
    archivoB03 = fullfile(rutaSubcarpeta, 'B03.png');
    archivoB04 = fullfile(rutaSubcarpeta, 'B04.png');
    
    if exist(archivoB02, 'file') && exist(archivoB03, 'file') && exist(archivoB04, 'file')
        % Leer las imágenes
        B02 = imread(archivoB02);
        B03 = imread(archivoB03);
        B04 = imread(archivoB04);
        
        % Convertir a double y aplicar tail clipping: valores de entrada [0,150/255]
        B02_adj = imadjust(im2double(B02), [0 100/255], []);
        B03_adj = imadjust(im2double(B03), [0 100/255], []);
        B04_adj = imadjust(im2double(B04), [0 100/255], []);
        
        % La composición de color verdadero se arma asignando:
        % R: B04, G: B03, B: B02
        colorVerdadero = cat(3, B04_adj, B03_adj, B02_adj);
    else
        warning('Faltan bandas para composición de color verdadero en la carpeta %s', subcarpetas{i});
        continue; % Salta a la siguiente subcarpeta
    end
    
    %% Composición de Color Falso
    % Se usa: B08.png para la componente roja (NIR), 
    % y se reusan B04.png y B03.png para verde y azul, respectivamente.
    archivoB08 = fullfile(rutaSubcarpeta, 'B08.png');
    if exist(archivoB08, 'file')
        B08 = imread(archivoB08);
        % Para mayor consistencia, se vuelven a procesar B04 y B03
        B04 = imread(archivoB04);
        B03 = imread(archivoB03);
        
        % Aplicar el mismo tail clipping: [0,150/255]
        B08_adj = imadjust(im2double(B08), [0 150/255], []);
        B04_adj = imadjust(im2double(B04), [0 150/255], []);
        B03_adj = imadjust(im2double(B03), [0 150/255], []);
        
        % La composición de color falso asigna:
        % R: B08, G: B04, B: B03
        colorFalso = cat(3, B08_adj, B04_adj, B03_adj);
    else
        warning('Falta la banda B08 para composición de color falso en la carpeta %s', subcarpetas{i});
        continue;
    end
    
    %% Mostrar las composiciones en una figura
    figure('Name', ['Composiciones - ' subcarpetas{i}], 'NumberTitle','off');
    
    % Mostrar color verdadero
    subplot(1,2,1);
    imshow(colorVerdadero);
    title(['Color Verdadero - ' subcarpetas{i}]);
    
    % Mostrar color falso
    subplot(1,2,2);
    imshow(colorFalso);
    title(['Color Falso - ' subcarpetas{i}]);
end