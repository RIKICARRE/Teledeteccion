% Script para extraer y mostrar histogramas de las bandas B02, B03, B04, B08, B08A, B11 y B12
% en las subcarpetas dentro de "Fotos_T".

% Definir la ruta principal
rutaPrincipal = 'Fotos_T';

% Subcarpetas a procesar (ajusta los nombres si son diferentes)
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
    % Construir la ruta completa a la subcarpeta
    rutaSubcarpeta = fullfile(rutaPrincipal, subcarpetas{i});
    
    % Definir las rutas de los archivos de cada banda
    archivoB02 = fullfile(rutaSubcarpeta, 'B02.png');
    archivoB03 = fullfile(rutaSubcarpeta, 'B03.png');
    archivoB04 = fullfile(rutaSubcarpeta, 'B04.png');
    archivoB08 = fullfile(rutaSubcarpeta, 'B08.png');
    archivoB08A = fullfile(rutaSubcarpeta, 'B08A.png');
    archivoB11 = fullfile(rutaSubcarpeta, 'B11.png');
    archivoB12 = fullfile(rutaSubcarpeta, 'B12.png');
    
    % Verificar que todos los archivos existan
    if exist(archivoB02, 'file') && exist(archivoB03, 'file') && ...
       exist(archivoB04, 'file') && exist(archivoB08, 'file') && ...
       exist(archivoB08A, 'file') && exist(archivoB11, 'file') && ...
       exist(archivoB12, 'file')
   
        % Cargar las imágenes de cada banda
        B02 = imread(archivoB02);
        B03 = imread(archivoB03);
        B04 = imread(archivoB04);
        B08 = imread(archivoB08);
        B08A = imread(archivoB08A);
        B11 = imread(archivoB11);
        B12 = imread(archivoB12);
        
        % Crear una figura para mostrar los histogramas
        figure('Name', ['Histogramas - ' subcarpetas{i}], 'NumberTitle','off');
        
        % Organizar los histogramas en un arreglo de 2 filas x 4 columnas
        % Subplot 1: Histograma de B02
        subplot(2,4,1);
        histogram(B02(:), 256);
        title(['Histograma B02 - ' subcarpetas{i}]);
        xlabel('Intensidad'); ylabel('Frecuencia');
        
        % Subplot 2: Histograma de B03
        subplot(2,4,2);
        histogram(B03(:), 256);
        title(['Histograma B03 - ' subcarpetas{i}]);
        xlabel('Intensidad'); ylabel('Frecuencia');
        
        % Subplot 3: Histograma de B04
        subplot(2,4,3);
        histogram(B04(:), 256);
        title(['Histograma B04 - ' subcarpetas{i}]);
        xlabel('Intensidad'); ylabel('Frecuencia');
        
        % Subplot 4: Histograma de B08
        subplot(2,4,4);
        histogram(B08(:), 256);
        title(['Histograma B08 - ' subcarpetas{i}]);
        xlabel('Intensidad'); ylabel('Frecuencia');
        
        % Subplot 5: Histograma de B08A
        subplot(2,4,5);
        histogram(B08A(:), 256);
        title(['Histograma B08A - ' subcarpetas{i}]);
        xlabel('Intensidad'); ylabel('Frecuencia');
        
        % Subplot 6: Histograma de B11
        subplot(2,4,6);
        histogram(B11(:), 256);
        title(['Histograma B11 - ' subcarpetas{i}]);
        xlabel('Intensidad'); ylabel('Frecuencia');
        
        % Subplot 7: Histograma de B12
        subplot(2,4,7);
        histogram(B12(:), 256);
        title(['Histograma B12 - ' subcarpetas{i}]);
        xlabel('Intensidad'); ylabel('Frecuencia');
        
        % Subplot 8: Dejar en blanco
        subplot(2,4,8);
        axis off;
        
    else
        warning('No se encontró alguna de las bandas en la carpeta %s', subcarpetas{i});
    end
end