%% Script para aplicar filtro de mediana selectivo a las imágenes clasificadas NDVI

function filtroMedianaClasificacion()
    % Carpeta donde se encuentran las clasificaciones guardadas
    carpetaClasificados = fullfile('NDVIs', 'Clasificados');
    
    % Verificar que la carpeta existe
    if ~exist(carpetaClasificados, 'dir')
        error('La carpeta %s no existe. Ejecute primero el script de clasificación NDVI.', carpetaClasificados);
    end
    
    % Crear carpeta para guardar los resultados filtrados si no existe
    carpetaFiltrados = fullfile(carpetaClasificados, 'Filtrados');
    if ~exist(carpetaFiltrados, 'dir')
        mkdir(carpetaFiltrados);
        fprintf('Se ha creado la carpeta %s para guardar las clasificaciones filtradas\n', carpetaFiltrados);
    end
    
    % Obtener todos los archivos de clasificación PNG
    archivosClasificacion = dir(fullfile(carpetaClasificados, 'Clasificacion_*.png'));
    
    if isempty(archivosClasificacion)
        fprintf('No se encontraron archivos de clasificación en la carpeta %s\n', carpetaClasificados);
        return;
    end
    
    % Obtener todos los archivos de categorías MAT
    archivosCategoria = dir(fullfile(carpetaClasificados, 'Categorias_*.mat'));
    
    if isempty(archivosCategoria)
        fprintf('No se encontraron archivos de categorías en la carpeta %s\n', carpetaClasificados);
        return;
    end
    
    fprintf('Se encontraron %d imágenes clasificadas para filtrar\n', length(archivosClasificacion));
    
    % Tamaño de la ventana del filtro de mediana (debe ser impar)
    tamanoVentana = 5;
    
    % Procesar cada imagen clasificada
    for i = 1:length(archivosClasificacion)
        nombreArchivo = archivosClasificacion(i).name;
        rutaCompleta = fullfile(carpetaClasificados, nombreArchivo);
        
        fprintf('Procesando %s (%d/%d)...\n', nombreArchivo, i, length(archivosClasificacion));
        
        % Extraer fecha de la imagen (asumiendo formato Clasificacion_fecha.png)
        [~, nombreBase] = fileparts(nombreArchivo);
        fechaStr = strrep(nombreBase, 'Clasificacion_', '');
        
        % Buscar el archivo de categorías correspondiente
        nombreCategorias = sprintf('Categorias_%s.mat', fechaStr);
        rutaCategorias = fullfile(carpetaClasificados, nombreCategorias);
        
        if ~exist(rutaCategorias, 'file')
            fprintf('No se encontró el archivo de categorías para %s, omitiendo...\n', nombreArchivo);
            continue;
        end
        
        % Cargar la imagen clasificada y las categorías
        imagenClasificada = imread(rutaCompleta);
        dataCategorias = load(rutaCategorias);
        categorias = dataCategorias.categorias;
        
        % Aplicar filtro de mediana selectivo a las categorías
        categoriasFiltradas = aplicarFiltroMedianaSelectivo(categorias, tamanoVentana);
        
        % Convertir las categorías filtradas de nuevo a imagen RGB
        imagenFiltrada = categoriasARGB(categoriasFiltradas);
        
        % Guardar la imagen filtrada
        nombreSalida = fullfile(carpetaFiltrados, sprintf('Filtrado_%s.png', fechaStr));
        imwrite(imagenFiltrada, nombreSalida);
        
        % Guardar también las categorías filtradas para análisis posterior
        nombreCategoriaFiltrada = fullfile(carpetaFiltrados, sprintf('CategoriasFiltradas_%s.mat', fechaStr));
        save(nombreCategoriaFiltrada, 'categoriasFiltradas');
        
        fprintf('Filtro aplicado y guardado en %s\n', nombreSalida);
    end
    
    fprintf('Proceso completado. %d imágenes filtradas.\n', length(archivosClasificacion));
    
    % Mostrar mensaje de finalización
    msgbox(sprintf('Se han filtrado %d imágenes clasificadas.\nLos resultados se guardaron en la carpeta %s', ...
           length(archivosClasificacion), carpetaFiltrados), 'Proceso completado');
end

% Función para aplicar un filtro de mediana selectivo a las categorías
function categoriasFiltradas = aplicarFiltroMedianaSelectivo(categorias, tamanoVentana)
    % Crear una copia de las categorías originales
    categoriasFiltradas = categorias;
    
    % Obtener dimensiones
    [filas, columnas] = size(categorias);
    
    % Calcular el radio de la ventana
    radio = floor(tamanoVentana / 2);
    
    % Crear una imagen de bordes para identificar píxeles a filtrar
    bordes = detectarBordes(categorias);
    
    % Aplicar filtro de mediana solo a los píxeles en bordes
    for i = radio+1:filas-radio
        for j = radio+1:columnas-radio
            % Solo aplicar el filtro a píxeles en bordes
            if bordes(i, j)
                % Extraer ventana local
                ventana = categorias(i-radio:i+radio, j-radio:j+radio);
                
                % Aplicar filtro de mediana
                valorMediana = median(ventana(:));
                
                % Asignar el valor de la mediana
                categoriasFiltradas(i, j) = valorMediana;
            end
        end
    end
end

% Función para detectar bordes en la imagen de categorías
function bordes = detectarBordes(categorias)
    % Crear una imagen de bordes usando el operador de Sobel
    [Gx, Gy] = gradient(double(categorias));
    magnitudGradiente = sqrt(Gx.^2 + Gy.^2);
    
    % Umbralizar para obtener los bordes
    umbral = 0.5; % Ajustar según sea necesario
    bordes = magnitudGradiente > umbral;
    
    % Dilatar los bordes para incluir píxeles vecinos
    elementoEstructurante = strel('disk', 1);
    bordes = imdilate(bordes, elementoEstructurante);
end

% Función para convertir categorías a imagen RGB según el esquema de colores
function imagenRGB = categoriasARGB(categorias)
    % Obtener dimensiones
    [filas, columnas] = size(categorias);
    
    % Inicializar imagen RGB
    imagenRGB = zeros(filas, columnas, 3);
    
    % Crear máscaras para cada clase
    mascaraNubes = categorias == 1;      % Nubes y nieve
    mascaraAgua = categorias == 2;       % Agua
    mascaraMarchito = categorias == 3;   % Desnudo/marchito
    mascaraVegMedia = categorias == 4;   % Vegetación media
    mascaraVegDensa = categorias == 5;   % Vegetación densa
    
    % Asignar colores a cada clase (misma asignación que en clasificacionNDVI.m)
    % Nubes y nieve (blanco)
    imagenRGB(:,:,1) = mascaraNubes * 1;
    imagenRGB(:,:,2) = mascaraNubes * 1;
    imagenRGB(:,:,3) = mascaraNubes * 1;
    
    % Agua (azul)
    imagenRGB(:,:,1) = imagenRGB(:,:,1) + mascaraAgua * 0;
    imagenRGB(:,:,2) = imagenRGB(:,:,2) + mascaraAgua * 0.2;
    imagenRGB(:,:,3) = imagenRGB(:,:,3) + mascaraAgua * 0.8;
    
    % Desnudo/marchito (marrón/beige)
    imagenRGB(:,:,1) = imagenRGB(:,:,1) + mascaraMarchito * 0.8;
    imagenRGB(:,:,2) = imagenRGB(:,:,2) + mascaraMarchito * 0.7;
    imagenRGB(:,:,3) = imagenRGB(:,:,3) + mascaraMarchito * 0.3;
    
    % Vegetación media (verde claro)
    imagenRGB(:,:,1) = imagenRGB(:,:,1) + mascaraVegMedia * 0.4;
    imagenRGB(:,:,2) = imagenRGB(:,:,2) + mascaraVegMedia * 0.8;
    imagenRGB(:,:,3) = imagenRGB(:,:,3) + mascaraVegMedia * 0.4;
    
    % Vegetación densa (verde oscuro)
    imagenRGB(:,:,1) = imagenRGB(:,:,1) + mascaraVegDensa * 0;
    imagenRGB(:,:,2) = imagenRGB(:,:,2) + mascaraVegDensa * 0.6;
    imagenRGB(:,:,3) = imagenRGB(:,:,3) + mascaraVegDensa * 0;
end