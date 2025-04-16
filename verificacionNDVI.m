%% Script para verificar la interpretación correcta de las imágenes NDVI

function verificacionNDVI()
    % Carpeta donde se encuentran los NDVI guardados
    carpetaNDVI = 'NDVIs';
    
    % Verificar que la carpeta existe
    if ~exist(carpetaNDVI, 'dir')
        error('La carpeta NDVIs no existe. Ejecute primero el script de generación de NDVI.');
    end
    
    % Obtener todos los archivos PNG de la carpeta NDVIs
    archivosNDVI = dir(fullfile(carpetaNDVI, 'NDVI_*.png'));
    
    if isempty(archivosNDVI)
        fprintf('No se encontraron archivos NDVI en la carpeta %s\n', carpetaNDVI);
        return;
    end
    
    % Seleccionar un archivo para verificación (preferiblemente uno post-incendio y uno reciente)
    % Por ejemplo, el primer archivo (2017) y uno de los últimos (2023 o 2024)
    indices = [1, length(archivosNDVI)]; % Primer y último archivo
    
    figure('Name', 'Verificación de interpretación NDVI', 'Position', [100, 100, 1200, 800]);
    
    for i = 1:length(indices)
        idx = indices(i);
        nombreArchivo = archivosNDVI(idx).name;
        rutaCompleta = fullfile(carpetaNDVI, nombreArchivo);
        
        % Extraer fecha de la imagen
        [~, nombreBase] = fileparts(nombreArchivo);
        fechaStr = strrep(nombreBase, 'NDVI_', '');
        
        % Leer la imagen NDVI
        imagenNDVI = imread(rutaCompleta);
        
        % Verificar si la imagen necesita conversión a escala de grises
        if size(imagenNDVI, 3) > 1
            % Usar el canal verde
            imagenVerde = double(imagenNDVI(:,:,2));
            maxValor = 255; % valor máximo para uint8
            
            % Interpretación 1: Original
            ndvi_original = (imagenVerde / maxValor) * 1.5 - 0.5;
            
            % Interpretación 2: Invertida
            ndvi_invertido = 1 - ((imagenVerde / maxValor) * 1.5 - 0.5);
            
            % Mostrar ambas interpretaciones
            subplot(2, 3, (i-1)*3 + 1);
            imshow(imagenNDVI);
            title(sprintf('NDVI Original - %s', fechaStr));
            
            subplot(2, 3, (i-1)*3 + 2);
            imagesc(ndvi_original, [-0.5, 1]);
            colormap(gca, jet);
            colorbar;
            title(sprintf('Interpretación 1 (Original) - %s', fechaStr));
            axis image;
            
            subplot(2, 3, (i-1)*3 + 3);
            imagesc(ndvi_invertido, [-0.5, 1]);
            colormap(gca, jet);
            colorbar;
            title(sprintf('Interpretación 2 (Invertida) - %s', fechaStr));
            axis image;
            
            % Calcular estadísticas para comparar
            fprintf('Estadísticas para %s:\n', fechaStr);
            fprintf('  Interpretación 1 (Original): Media=%.4f, Min=%.4f, Max=%.4f\n', ...
                mean(ndvi_original(:)), min(ndvi_original(:)), max(ndvi_original(:)));
            fprintf('  Interpretación 2 (Invertida): Media=%.4f, Min=%.4f, Max=%.4f\n', ...
                mean(ndvi_invertido(:)), min(ndvi_invertido(:)), max(ndvi_invertido(:)));
        end
    end
end