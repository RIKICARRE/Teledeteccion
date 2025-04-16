%% Script para ajustar umbrales de agua en imágenes NDVI

function ajustarUmbralesAgua()
    % Carpeta donde se encuentran los NDVI guardados
    carpetaNDVI = 'NDVIs';
    
    % Verificar que la carpeta existe
    if ~exist(carpetaNDVI, 'dir')
        error('La carpeta NDVIs no existe. Ejecute primero el script de generación de NDVI.');
    end
    
    % Obtener todos los archivos PNG de la carpeta NDVIs
    archivosNDVI = dir(fullfile(carpetaNDVI, 'NDVI_31-03-2025.png'));
    
    if isempty(archivosNDVI)
        fprintf('No se encontraron archivos NDVI en la carpeta %s\n', carpetaNDVI);
        return;
    end
    
    % Seleccionar una imagen para pruebas (preferiblemente con agua visible)
    % Puedes cambiar el índice para probar con diferentes imágenes
    idx = 1; % Primera imagen
    nombreArchivo = archivosNDVI(idx).name;
    rutaCompleta = fullfile(carpetaNDVI, nombreArchivo);
    
    % Extraer fecha de la imagen
    [~, nombreBase] = fileparts(nombreArchivo);
    fechaStr = strrep(nombreBase, 'NDVI_', '');
    
    % Crear figura interactiva para ajustar umbrales
    figure('Name', sprintf('Ajuste de umbrales de agua - %s', fechaStr), 'Position', [100, 100, 1200, 800]);
    
    % Leer la imagen NDVI
    imagenNDVI = imread(rutaCompleta);
    
    % Verificar si la imagen necesita conversión a escala de grises
    if size(imagenNDVI, 3) > 1
        % Usar el canal verde
        imagenVerde = double(imagenNDVI(:,:,2));
        maxValor = 255; % valor máximo para uint8
        
        % Aplicar la inversión como en clasificacionNDVI.m
        ndvi = 1 - ((imagenVerde / maxValor) * 1.5 - 0.5);
    else
        ndvi = double(imagenNDVI);
        maxValor = double(max(imagenNDVI(:)));
        ndvi = 1 - ((ndvi / maxValor) * 1.5 - 0.5);
    end
    
    % Mostrar la imagen NDVI original
    subplot(2, 3, 1);
    imshow(imagenNDVI);
    title('Imagen RGB original');
    
    subplot(2, 3, 2);
    imagesc(ndvi, [-0.5, 1]);
    colormap(gca, jet);
    colorbar;
    title('NDVI procesado');
    axis image;
    
    % Crear controles deslizantes para ajustar umbrales
    umbralInferior = -0.1;
    umbralSuperior = 0.15;
    
    % Función para actualizar la visualización
    function actualizarVisualizacion(~, ~)
        % Crear máscara de agua con los umbrales actuales
        mascaraAgua = ndvi >= umbralInferior & ndvi < umbralSuperior;
        
        % Mostrar máscara de agua
        subplot(2, 3, 3);
        imagesc(mascaraAgua);
        colormap(gca, gray);
        title(sprintf('Máscara de agua\nUmbrales: [%.2f, %.2f)', umbralInferior, umbralSuperior));
        axis image;
        
        % Mostrar histograma con umbrales marcados
        subplot(2, 3, [4, 5, 6]);
        histogram(ndvi(:), 100);
        title('Histograma de valores NDVI');
        xlabel('Valor NDVI');
        ylabel('Frecuencia');
        hold on;
        
        % Marcar los umbrales en el histograma
        yLim = ylim;
        plot([umbralInferior umbralInferior], yLim, 'b--', 'LineWidth', 2);
        text(umbralInferior, 0.9*yLim(2), 'Umbral inferior', 'Color', 'b');
        
        plot([umbralSuperior umbralSuperior], yLim, 'r--', 'LineWidth', 2);
        text(umbralSuperior, 0.8*yLim(2), 'Umbral superior', 'Color', 'r');
        
        hold off;
        
        % Mostrar estadísticas
        fprintf('Porcentaje de píxeles clasificados como agua: %.2f%%\n', ...
            100 * sum(mascaraAgua(:)) / numel(mascaraAgua));
    end
    
    % Crear controles deslizantes
    uicontrol('Style', 'text', 'Position', [50, 50, 150, 20], ...
        'String', 'Umbral inferior agua:');
    sliderInferior = uicontrol('Style', 'slider', 'Position', [200, 50, 300, 20], ...
        'Min', -0.5, 'Max', 0.5, 'Value', umbralInferior, ...
        'Callback', @(src, ~) updateInferior(src));
    
    uicontrol('Style', 'text', 'Position', [50, 20, 150, 20], ...
        'String', 'Umbral superior agua:');
    sliderSuperior = uicontrol('Style', 'slider', 'Position', [200, 20, 300, 20], ...
        'Min', -0.5, 'Max', 1, 'Value', umbralSuperior, ...
        'Callback', @(src, ~) updateSuperior(src));
    
    % Funciones auxiliares para actualizar los umbrales
    function updateInferior(src)
        umbralInferior = get(src, 'Value');
        actualizarVisualizacion();
    end

    function updateSuperior(src)
        umbralSuperior = get(src, 'Value');
        actualizarVisualizacion();
    end
    
    % Mostrar visualización inicial
    actualizarVisualizacion();
    
    % Instrucciones
    fprintf('\n--- Instrucciones para ajustar umbrales de agua ---\n');
    fprintf('1. Use los controles deslizantes para ajustar los umbrales\n');
    fprintf('2. Observe cómo cambia la máscara de agua\n');
    fprintf('3. Una vez encontrados los umbrales óptimos, anótelos y actualice clasificacionNDVI.m\n');
    fprintf('   Valores actuales: umbralInferior = %.2f, umbralSuperior = %.2f\n', umbralInferior, umbralSuperior);
end