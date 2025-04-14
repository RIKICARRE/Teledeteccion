% Algoritmo para clasificación de imagen NDVI usando umbralización
% Este script carga una imagen NDVI, realiza umbralización y genera un mapa de clasificación

function mapaNDVI = clasificacionNDVI(rutaImagenNDVI)
    % Cargar la imagen NDVI
    if nargin < 1
        [nombreArchivo, rutaArchivo] = uigetfile({'*.tif;*.tiff;*.jpg;*.png'}, 'Seleccionar imagen NDVI');
        if nombreArchivo == 0
            error('No se seleccionó ninguna imagen.');
        end
        rutaImagenNDVI = fullfile(rutaArchivo, nombreArchivo);
    end
    
    % Leer la imagen NDVI
    imagenNDVI = imread(rutaImagenNDVI);
    
    % Verificar si la imagen necesita conversión a escala de grises
    if size(imagenNDVI, 3) > 1
        imagenNDVI = rgb2gray(imagenNDVI);
    end
    
    % Convertir a formato double para procesamiento
    imagenNDVI = double(imagenNDVI);
    
    % Normalizar los valores al rango típico NDVI [-1, 1] 
    % (Ajustar según el formato de tu imagen de entrada)
    if max(imagenNDVI(:)) > 1 || min(imagenNDVI(:)) < -1
        % Si la imagen está en formato de 8 o 16 bits
        maxValor = double(max(imagenNDVI(:)));
        imagenNDVI = (imagenNDVI / maxValor) * 2 - 1;
    end
    
    % Definir umbrales para clasificación de NDVI
    % Estos umbrales se pueden ajustar según las características específicas de la vegetación estudiada
    umbralAgua = -0.1;         % Agua: NDVI < -0.1
    umbralSuelo = 0.2;         % Suelo desnudo/áreas urbanas: -0.1 <= NDVI < 0.2
    umbralVegetacionBaja = 0.4; % Vegetación escasa/baja densidad: 0.2 <= NDVI < 0.4
    umbralVegetacionMedia = 0.6; % Vegetación moderada: 0.4 <= NDVI < 0.6
                               % Vegetación densa: NDVI >= 0.6
    
    % Inicializar el mapa de clasificación
    [filas, columnas] = size(imagenNDVI);
    mapaNDVI = zeros(filas, columnas, 3); % Mapa RGB para visualización
    
    % Crear máscara para cada clase
    mascaraAgua = imagenNDVI < umbralAgua;
    mascaraSuelo = imagenNDVI >= umbralAgua & imagenNDVI < umbralSuelo;
    mascaraVegBaja = imagenNDVI >= umbralSuelo & imagenNDVI < umbralVegetacionBaja;
    mascaraVegMedia = imagenNDVI >= umbralVegetacionBaja & imagenNDVI < umbralVegetacionMedia;
    mascaraVegDensa = imagenNDVI >= umbralVegetacionMedia;
    
    % Asignar colores a cada clase
    % Agua (azul)
    mapaNDVI(:,:,1) = mapaNDVI(:,:,1) + mascaraAgua * 0;
    mapaNDVI(:,:,2) = mapaNDVI(:,:,2) + mascaraAgua * 0;
    mapaNDVI(:,:,3) = mapaNDVI(:,:,3) + mascaraAgua * 1;
    
    % Suelo desnudo/áreas urbanas (marrón/gris)
    mapaNDVI(:,:,1) = mapaNDVI(:,:,1) + mascaraSuelo * 0.5;
    mapaNDVI(:,:,2) = mapaNDVI(:,:,2) + mascaraSuelo * 0.5;
    mapaNDVI(:,:,3) = mapaNDVI(:,:,3) + mascaraSuelo * 0.5;
    
    % Vegetación baja (verde claro)
    mapaNDVI(:,:,1) = mapaNDVI(:,:,1) + mascaraVegBaja * 0.8;
    mapaNDVI(:,:,2) = mapaNDVI(:,:,2) + mascaraVegBaja * 1;
    mapaNDVI(:,:,3) = mapaNDVI(:,:,3) + mascaraVegBaja * 0.8;
    
    % Vegetación media (verde medio)
    mapaNDVI(:,:,1) = mapaNDVI(:,:,1) + mascaraVegMedia * 0.1;
    mapaNDVI(:,:,2) = mapaNDVI(:,:,2) + mascaraVegMedia * 0.8;
    mapaNDVI(:,:,3) = mapaNDVI(:,:,3) + mascaraVegMedia * 0.1;
    
    % Vegetación densa (verde oscuro)
    mapaNDVI(:,:,1) = mapaNDVI(:,:,1) + mascaraVegDensa * 0;
    mapaNDVI(:,:,2) = mapaNDVI(:,:,2) + mascaraVegDensa * 0.6;
    mapaNDVI(:,:,3) = mapaNDVI(:,:,3) + mascaraVegDensa * 0;
    
    % Visualizar resultados
    figure;
    
    % Mostrar la imagen NDVI original
    subplot(1,2,1);
    imagesc(imagenNDVI, [-1 1]);
    colormap(gca, jet);
    colorbar;
    title('Imagen NDVI Original');
    axis image;
    
    % Mostrar el mapa de clasificación
    subplot(1,2,2);
    imshow(mapaNDVI);
    title('Mapa de Clasificación por Umbralización');
    
    % Añadir leyenda como texto
    annotation('textbox', [0.7, 0.15, 0.2, 0.2], 'String', ...
        {'Leyenda:', ...
         'Azul: Agua', ...
         'Gris: Suelo/Urbano', ...
         'Verde claro: Veg. baja', ...
         'Verde medio: Veg. media', ...
         'Verde oscuro: Veg. densa'}, ...
         'EdgeColor', 'none');
    
    % Si se quiere guardar el resultado
    respuesta = questdlg('¿Desea guardar el mapa de clasificación?', 'Guardar resultado', 'Sí', 'No', 'No');
    if strcmp(respuesta, 'Sí')
        [nombreGuardar, rutaGuardar] = uiputfile({'*.png', 'Archivo PNG'; '*.jpg', 'Archivo JPEG'; '*.tif', 'Archivo TIFF'}, 'Guardar mapa de clasificación');
        if nombreGuardar ~= 0
            imwrite(mapaNDVI, fullfile(rutaGuardar, nombreGuardar));
            msgbox('Mapa de clasificación guardado con éxito', 'Guardar');
        end
    end
    
    % También se puede devolver una versión categórica del mapa para análisis posterior
    if nargout > 1
        categorias = zeros(filas, columnas, 'uint8');
        categorias(mascaraAgua) = 1;        % Agua
        categorias(mascaraSuelo) = 2;       % Suelo
        categorias(mascaraVegBaja) = 3;     % Vegetación baja
        categorias(mascaraVegMedia) = 4;    % Vegetación media
        categorias(mascaraVegDensa) = 5;    % Vegetación densa
    end
end
