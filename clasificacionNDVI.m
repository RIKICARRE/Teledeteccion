%% Script para clasificación automática de todas las imágenes NDVI de la carpeta NDVIs

function clasificacionNDVI()
    % Carpeta donde se encuentran los NDVI guardados
    carpetaNDVI = 'NDVIs';
    
    % Verificar que la carpeta existe
    if ~exist(carpetaNDVI, 'dir')
        error('La carpeta NDVIs no existe. Ejecute primero el script de generación de NDVI.');
    end
    
    % Crear carpeta para guardar los resultados si no existe
    carpetaResultados = fullfile(carpetaNDVI, 'Clasificados');
    if ~exist(carpetaResultados, 'dir')
        mkdir(carpetaResultados);
        fprintf('Se ha creado la carpeta %s para guardar las clasificaciones\n', carpetaResultados);
    end
    
    % Obtener todos los archivos PNG de la carpeta NDVIs
    archivosNDVI = dir(fullfile(carpetaNDVI, 'NDVI_*.png'));
    
    if isempty(archivosNDVI)
        fprintf('No se encontraron archivos NDVI en la carpeta %s\n', carpetaNDVI);
        return;
    end
    
    fprintf('Se encontraron %d imágenes NDVI para clasificar\n', length(archivosNDVI));
    
    % Procesar cada imagen NDVI
    for i = 1:length(archivosNDVI)
        nombreArchivo = archivosNDVI(i).name;
        rutaCompleta = fullfile(carpetaNDVI, nombreArchivo);
        
        fprintf('Procesando %s (%d/%d)...\n', nombreArchivo, i, length(archivosNDVI));
        
        % Extraer fecha de la imagen (asumiendo formato NDVI_fecha.png)
        [~, nombreBase] = fileparts(nombreArchivo);
        fechaStr = strrep(nombreBase, 'NDVI_', '');
        
        % Clasificar la imagen NDVI
        [mapaNDVI, categorias] = procesarImagen(rutaCompleta, false); % false = no mostrar figuras
        
        % Guardar la imagen clasificada con el mismo nombre base pero en la carpeta de resultados
        nombreSalida = fullfile(carpetaResultados, sprintf('Clasificacion_%s.png', fechaStr));
        imwrite(mapaNDVI, nombreSalida);
        
        % Guardar también la imagen de categorías para análisis posterior
        nombreCategoria = fullfile(carpetaResultados, sprintf('Categorias_%s.mat', fechaStr));
        save(nombreCategoria, 'categorias');
        
        fprintf('Clasificación guardada en %s\n', nombreSalida);
    end
    
    fprintf('Proceso completado. %d imágenes clasificadas.\n', length(archivosNDVI));
    
    % Mostrar mensaje de finalización
    msgbox(sprintf('Se han clasificado %d imágenes NDVI.\nLos resultados se guardaron en la carpeta %s', ...
           length(archivosNDVI), carpetaResultados), 'Proceso completado');
end

% Función modificada para la clasificación de una imagen NDVI con colores corregidos
function [mapaNDVI, categorias] = procesarImagen(rutaImagenNDVI, mostrarFiguras)
    % Parámetro mostrarFiguras es opcional, por defecto true
    if nargin < 2
        mostrarFiguras = true;
    end
    
    % Leer la imagen NDVI
    imagenNDVI = imread(rutaImagenNDVI);
    
    % Verificar si la imagen necesita conversión a escala de grises
    if size(imagenNDVI, 3) > 1
        % Determinar qué canal tiene más información - usualmente el verde (2)
        imagenVerde = double(imagenNDVI(:,:,2));
        
        % CORRECCIÓN: En lugar de aproximar, verificar si los valores necesitan ser invertidos
        % Esto depende de cómo se generaron las imágenes NDVI originalmente
        maxValor = 255; % valor máximo para uint8
        
        % Analizar la distribución para determinar si necesitamos invertir
        % Si hay más píxeles verdes oscuros (alta vegetación) que claros, invertiríamos
        % Esta es una heurística y puede necesitar ajustes según tus datos específicos
        
        % Por defecto, suponemos que los valores altos representan vegetación densa
        imagenNDVI = (imagenVerde / maxValor) * 1.5 - 0.5; % aproximar al rango [-0.5, 1]
        
        % SOLUCIÓN 1: Si la inversión es el problema, descomenta esta línea para invertir la escala
        % imagenNDVI = 1 - ((imagenVerde / maxValor) * 1.5 - 0.5);
    else
        % Si ya está en escala de grises, normalizamos
        imagenNDVI = double(imagenNDVI);
        maxValor = double(max(imagenNDVI(:)));
        imagenNDVI = (imagenNDVI / maxValor) * 1.5 - 0.5; % aproximar al rango [-0.5, 1]
    end
    
    % Definir umbrales ajustados basados en la imagen de referencia
    umbralNubes = -0.1;       % Nubes y nieve: NDVI < -0.1
    umbralAgua = 0.05;        % Agua: -0.1 <= NDVI < 0.05
    umbralMarchito = 0.25;    % Desnudo/marchito: 0.05 <= NDVI < 0.25
    umbralVegMedia = 0.5;     % Vegetación media: 0.25 <= NDVI < 0.5
                             % Vegetación densa: NDVI >= 0.5
    
    % Inicializar el mapa de clasificación
    [filas, columnas] = size(imagenNDVI);
    mapaNDVI = zeros(filas, columnas, 3); % Mapa RGB para visualización
    
    % Crear máscara para cada clase
    mascaraNubes = imagenNDVI < umbralNubes;
    mascaraAgua = imagenNDVI >= umbralNubes & imagenNDVI < umbralAgua;
    mascaraMarchito = imagenNDVI >= umbralAgua & imagenNDVI < umbralMarchito;
    mascaraVegMedia = imagenNDVI >= umbralMarchito & imagenNDVI < umbralVegMedia;
    mascaraVegDensa = imagenNDVI >= umbralVegMedia;
    
    % SOLUCIÓN 2: Corregir la asignación de colores - cambiar verde oscuro y amarillo/beige
    
    % Asignar colores a cada clase (nueva asignación)
    % Nubes y nieve (blanco)
    mapaNDVI(:,:,1) = mascaraNubes * 1;
    mapaNDVI(:,:,2) = mascaraNubes * 1;
    mapaNDVI(:,:,3) = mascaraNubes * 1;
    
    % Agua (azul)
    mapaNDVI(:,:,1) = mapaNDVI(:,:,1) + mascaraAgua * 0;
    mapaNDVI(:,:,2) = mapaNDVI(:,:,2) + mascaraAgua * 0.2;
    mapaNDVI(:,:,3) = mapaNDVI(:,:,3) + mascaraAgua * 0.8;
    
    % CORREGIDO: Vegetación densa ahora es amarillo/beige (antes verde oscuro)
    mapaNDVI(:,:,1) = mapaNDVI(:,:,1) + mascaraVegDensa * 0.8;
    mapaNDVI(:,:,2) = mapaNDVI(:,:,2) + mascaraVegDensa * 0.8;
    mapaNDVI(:,:,3) = mapaNDVI(:,:,3) + mascaraVegDensa * 0.2;
    
    % Vegetación media (verde claro)
    mapaNDVI(:,:,1) = mapaNDVI(:,:,1) + mascaraVegMedia * 0.4;
    mapaNDVI(:,:,2) = mapaNDVI(:,:,2) + mascaraVegMedia * 0.8;
    mapaNDVI(:,:,3) = mapaNDVI(:,:,3) + mascaraVegMedia * 0.4;
    
    % CORREGIDO: Desnudo/marchito ahora es verde oscuro (antes amarillo/beige)
    mapaNDVI(:,:,1) = mapaNDVI(:,:,1) + mascaraMarchito * 0;
    mapaNDVI(:,:,2) = mapaNDVI(:,:,2) + mascaraMarchito * 0.6;
    mapaNDVI(:,:,3) = mapaNDVI(:,:,3) + mascaraMarchito * 0;
    
    % Crear también una versión categórica del mapa para análisis posterior
    categorias = zeros(filas, columnas, 'uint8');
    categorias(mascaraNubes) = 1;      % Nubes y nieve
    categorias(mascaraAgua) = 2;       % Agua
    categorias(mascaraMarchito) = 3;   % Desnudo/marchito
    categorias(mascaraVegMedia) = 4;   % Vegetación media
    categorias(mascaraVegDensa) = 5;   % Vegetación densa
    
    % Visualizar resultados si se solicita
    if mostrarFiguras
        figure;
        
        % Mostrar la imagen NDVI original
        subplot(1,3,1);
        imagesc(imagenNDVI, [-0.5 1]);
        colormap(gca, jet);
        colorbar;
        title('Imagen NDVI Original');
        axis image;
        
        % Mostrar el mapa de clasificación
        subplot(1,3,2);
        imshow(mapaNDVI);
        title('Mapa de Clasificación por Umbralización');
        
        % Añadir histograma para ayudar en el análisis
        subplot(1,3,3);
        histogram(imagenNDVI(:), 100);
        title('Histograma de valores NDVI');
        xlabel('Valor NDVI');
        ylabel('Frecuencia');
        hold on;
        
        % Marcar los umbrales en el histograma
        yLim = ylim;
        plot([umbralNubes umbralNubes], yLim, 'w--', 'LineWidth', 1);
        plot([umbralAgua umbralAgua], yLim, 'b--', 'LineWidth', 1);
        plot([umbralMarchito umbralMarchito], yLim, 'g--', 'LineWidth', 1);
        plot([umbralVegMedia umbralVegMedia], yLim, 'y--', 'LineWidth', 1);
        
        % Añadir leyenda como texto fuera de los subplots
        annotation('textbox', [0.15, 0.02, 0.7, 0.05], 'String', ...
            {'Leyenda: Blanco: Nubes/nieve | Azul: Agua | Verde oscuro: Marchito | Verde claro: Veg. media | Amarillo: Veg. densa'}, ...
            'EdgeColor', 'none', 'HorizontalAlignment', 'center');
    end
    
    % Opción adicional para analizar y hacer un debug de la clasificación
    if mostrarFiguras
        % Crear una figura para analizar con más detalle la distribución
        figure;
        
        % Mostrar histograma con más detalle
        subplot(2,1,1);
        hist = histogram(imagenNDVI(:), 100, 'Normalization', 'probability');
        title('Distribución detallada de valores NDVI');
        xlabel('Valor NDVI');
        ylabel('Frecuencia relativa');
        grid on;
        
        % Añadir umbrales con etiquetas
        hold on;
        yLim = ylim;
        plot([umbralNubes umbralNubes], yLim, 'r--', 'LineWidth', 2);
        text(umbralNubes, 0.9*yLim(2), 'Nubes', 'Color', 'r');
        
        plot([umbralAgua umbralAgua], yLim, 'b--', 'LineWidth', 2);
        text(umbralAgua, 0.8*yLim(2), 'Agua', 'Color', 'b');
        
        plot([umbralMarchito umbralMarchito], yLim, 'g--', 'LineWidth', 2);
        text(umbralMarchito, 0.7*yLim(2), 'Marchito', 'Color', 'g');
        
        plot([umbralVegMedia umbralVegMedia], yLim, 'y--', 'LineWidth', 2);
        text(umbralVegMedia, 0.6*yLim(2), 'Veg. media', 'Color', [0.8 0.8 0]);
        
        % Añadir gráfico acumulativo para ayudar a seleccionar umbrales
        subplot(2,1,2);
        [counts, edges] = histcounts(imagenNDVI(:), 100);
        centers = (edges(1:end-1) + edges(2:end))/2;
        cumulative = cumsum(counts)/sum(counts);
        plot(centers, cumulative, 'b-', 'LineWidth', 2);
        grid on;
        title('Distribución acumulativa de valores NDVI');
        xlabel('Valor NDVI');
        ylabel('Frecuencia acumulada');
        
        % Añadir líneas para los percentiles importantes (25%, 50%, 75%)
        hold on;
        yLim = [0 1];
        xLim = xlim;
        
        plot(xLim, [0.25 0.25], 'k:', 'LineWidth', 1);
        text(xLim(1), 0.25, '25%', 'HorizontalAlignment', 'left');
        
        plot(xLim, [0.5 0.5], 'k:', 'LineWidth', 1);
        text(xLim(1), 0.5, '50%', 'HorizontalAlignment', 'left');
        
        plot(xLim, [0.75 0.75], 'k:', 'LineWidth', 1);
        text(xLim(1), 0.75, '75%', 'HorizontalAlignment', 'left');
    end
end