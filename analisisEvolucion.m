%% Script para analizar la evolución temporal de la recuperación post-incendio en Doñana
% Este script analiza las imágenes clasificadas y filtradas para generar gráficos
% que muestran la evolución temporal de la vegetación y otros elementos del paisaje
% tras el incendio de 2017 en el Parque Nacional de Doñana.

function analisisEvolucion()
    % Carpeta donde se encuentran las clasificaciones filtradas
    carpetaFiltrados = fullfile('NDVIs', 'Clasificados', 'Filtrados');
    
    % Verificar que la carpeta existe
    if ~exist(carpetaFiltrados, 'dir')
        error(['La carpeta %s no existe. Ejecute primero los scripts de clasificación ' ...
               'y filtrado de NDVI.'], carpetaFiltrados);
    end
    
    % Fechas de las imágenes en orden cronológico
    fechas = {'21-06-2017', '26-06-2017', '26-06-2018', '21-06-2019', ...
              '30-06-2020', '30-06-2021', '30-06-2022', '30-06-2023', ...
              '24-06-2024', '31-03-2025'};
    
    % Convertir fechas a formato datetime para mejor visualización en gráficos
    fechasDateTime = datetime();
    fechasFormateadas = {};
    for i = 1:length(fechas)
        partesFecha = split(fechas{i}, '-');
        fechaTmp = datetime(str2double(partesFecha{3}), str2double(partesFecha{2}), str2double(partesFecha{1}));
        fechasDateTime(i) = fechaTmp;
        fechasFormateadas{i} = datestr(fechaTmp, 'mmm yyyy');
    end
    
    % Inicializar matrices para almacenar datos de cada categoría por fecha
    numFechas = length(fechas);
    porcentajeNubes = zeros(1, numFechas);
    porcentajeAgua = zeros(1, numFechas);
    porcentajeMarchito = zeros(1, numFechas);
    porcentajeVegMedia = zeros(1, numFechas);
    porcentajeVegDensa = zeros(1, numFechas);
    
    % Inicializar matriz para índice de recuperación
    indiceRecuperacion = zeros(1, numFechas);
    
    % Procesar cada fecha
    for i = 1:numFechas
        % Buscar el archivo de categorías filtradas correspondiente
        nombreArchivo = sprintf('CategoriasFiltradas_%s.mat', fechas{i});
        rutaArchivo = fullfile(carpetaFiltrados, nombreArchivo);
        
        % Verificar si existe el archivo
        if ~exist(rutaArchivo, 'file')
            warning('No se encontró el archivo %s. Se omitirá esta fecha.', nombreArchivo);
            continue;
        end
        
        % Cargar las categorías filtradas
        datos = load(rutaArchivo);
        categorias = datos.categoriasFiltradas;
        
        % Calcular el porcentaje de cada categoría
        totalPixeles = numel(categorias);
        
        % Contar píxeles por categoría
        numNubes = sum(categorias(:) == 1);
        numAgua = sum(categorias(:) == 2);
        numMarchito = sum(categorias(:) == 3);
        numVegMedia = sum(categorias(:) == 4);
        numVegDensa = sum(categorias(:) == 5);
        
        % Calcular porcentajes (excluyendo nubes para normalizar)
        pixelesSinNubes = totalPixeles - numNubes;
        
        porcentajeNubes(i) = (numNubes / totalPixeles) * 100;
        porcentajeAgua(i) = (numAgua / pixelesSinNubes) * 100;
        porcentajeMarchito(i) = (numMarchito / pixelesSinNubes) * 100;
        porcentajeVegMedia(i) = (numVegMedia / pixelesSinNubes) * 100;
        porcentajeVegDensa(i) = (numVegDensa / pixelesSinNubes) * 100;
        
        % Calcular índice de recuperación (ponderado por tipo de vegetación)
        % Marchito = 0.2, Veg. Media = 0.6, Veg. Densa = 1.0
        indiceRecuperacion(i) = (0.2 * numMarchito + 0.6 * numVegMedia + 1.0 * numVegDensa) / pixelesSinNubes;
    end
    
    % Crear carpeta para guardar los resultados si no existe
    carpetaResultados = 'Resultados_Analisis';
    if ~exist(carpetaResultados, 'dir')
        mkdir(carpetaResultados);
        fprintf('Se ha creado la carpeta %s para guardar los resultados del análisis\n', carpetaResultados);
    end
    
    %% Gráfico 1: Evolución temporal de las categorías de cobertura
    figure('Name', 'Evolución de la cobertura del suelo', 'Position', [100, 100, 1000, 600]);
    
    % Crear gráfico de área apilada
    area(1:numFechas, [porcentajeAgua; porcentajeMarchito; porcentajeVegMedia; porcentajeVegDensa]', ...
        'LineWidth', 1.5);
    
    % Configurar apariencia
    colormap([0 0.2 0.8; 0 0.6 0; 0.4 0.8 0.4; 0.8 0.8 0.2]); % Colores correspondientes a las categorías
    
    % Añadir etiquetas y título
    title('Evolución de la cobertura del suelo post-incendio (2017-2025)', 'FontSize', 14);
    xlabel('Fecha', 'FontSize', 12);
    ylabel('Porcentaje de área (%)', 'FontSize', 12);
    
    % Configurar eje X con las fechas
    xticks(1:numFechas);
    xticklabels(fechasFormateadas);
    xtickangle(45);
    
    % Añadir leyenda
    legend('Agua', 'Suelo desnudo/Vegetación marchita', 'Vegetación media', 'Vegetación densa', ...
        'Location', 'eastoutside');
    
    % Añadir cuadrícula
    grid on;
    
    % Guardar figura
    saveas(gcf, fullfile(carpetaResultados, 'Evolucion_Cobertura_Suelo.png'));
    saveas(gcf, fullfile(carpetaResultados, 'Evolucion_Cobertura_Suelo.fig'));
    
    %% Gráfico 2: Índice de recuperación a lo largo del tiempo
    figure('Name', 'Índice de Recuperación', 'Position', [100, 100, 1000, 500]);
    
    % Crear gráfico de línea con marcadores
    plot(1:numFechas, indiceRecuperacion, '-o', 'LineWidth', 2, 'MarkerSize', 8, ...
        'MarkerFaceColor', 'auto');
    
    % Añadir etiquetas y título
    title('Índice de Recuperación Vegetal post-incendio (2017-2025)', 'FontSize', 14);
    xlabel('Fecha', 'FontSize', 12);
    ylabel('Índice de Recuperación (0-1)', 'FontSize', 12);
    
    % Configurar eje X con las fechas
    xticks(1:numFechas);
    xticklabels(fechasFormateadas);
    xtickangle(45);
    
    % Añadir cuadrícula
    grid on;
    
    % Añadir línea de tendencia
    hold on;
    p = polyfit(1:numFechas, indiceRecuperacion, 2); % Ajuste polinómico de segundo grado
    x_trend = linspace(1, numFechas, 100);
    y_trend = polyval(p, x_trend);
    plot(x_trend, y_trend, 'r--', 'LineWidth', 1.5);
    
    % Añadir leyenda
    legend('Índice de recuperación', 'Tendencia', 'Location', 'southeast');
    
    % Guardar figura
    saveas(gcf, fullfile(carpetaResultados, 'Indice_Recuperacion.png'));
    saveas(gcf, fullfile(carpetaResultados, 'Indice_Recuperacion.fig'));
    
    %% Gráfico 3: Tasa de cambio anual
    % Calcular tasas de cambio para vegetación (densa + media)
    vegetacionTotal = porcentajeVegDensa + porcentajeVegMedia;
    tasaCambio = zeros(1, numFechas-1);
    
    for i = 1:numFechas-1
        % Calcular diferencia porcentual respecto al año anterior
        tasaCambio(i) = ((vegetacionTotal(i+1) - vegetacionTotal(i)) / vegetacionTotal(i)) * 100;
    end
    
    figure('Name', 'Tasa de Cambio Anual', 'Position', [100, 100, 1000, 500]);
    
    % Crear gráfico de barras
    bar(2:numFechas, tasaCambio, 'FaceColor', [0.3 0.6 0.3]);
    
    % Añadir etiquetas y título
    title('Tasa de Cambio Anual en Cobertura Vegetal (%)', 'FontSize', 14);
    xlabel('Período', 'FontSize', 12);
    ylabel('Cambio porcentual (%)', 'FontSize', 12);
    
    % Configurar eje X con los períodos
    periodos = cell(numFechas-1, 1);
    for i = 1:numFechas-1
        periodos{i} = [fechasFormateadas{i} ' → ' fechasFormateadas{i+1}];
    end
    xticks(2:numFechas);
    xticklabels(periodos);
    xtickangle(45);
    
    % Añadir línea de referencia en y=0
    hold on;
    plot([1.5, numFechas+0.5], [0, 0], 'k--', 'LineWidth', 1);
    
    % Añadir etiquetas de valor en cada barra
    for i = 1:length(tasaCambio)
        if tasaCambio(i) >= 0
            text(i+1, tasaCambio(i)+1, ['+' num2str(tasaCambio(i), '%.1f') '%'], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontWeight', 'bold');
        else
            text(i+1, tasaCambio(i)-1, [num2str(tasaCambio(i), '%.1f') '%'], ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'top', 'FontWeight', 'bold');
        end
    end
    
    % Añadir cuadrícula
    grid on;
    
    % Guardar figura
    saveas(gcf, fullfile(carpetaResultados, 'Tasa_Cambio_Anual.png'));
    saveas(gcf, fullfile(carpetaResultados, 'Tasa_Cambio_Anual.fig'));
    
    %% Gráfico 4: Mapa de calor de la evolución temporal
    figure('Name', 'Mapa de Calor de Evolución', 'Position', [100, 100, 1000, 600]);

    % Preparar datos para el mapa de calor
    datosHeatmap = [porcentajeAgua; porcentajeMarchito; porcentajeVegMedia; porcentajeVegDensa];

    % MODIFICACIÓN: Usar fechas originales en lugar de fechas formateadas para evitar duplicados
    h = heatmap(fechas, {'Agua', 'Suelo desnudo/Veg. marchita', 'Vegetación media', 'Vegetación densa'}, ...
        datosHeatmap, 'ColorbarVisible', 'on');

    % Configurar apariencia
    h.Title = 'Evolución de la cobertura del suelo (%)';
    h.XLabel = 'Fecha';
    h.YLabel = 'Categoría';

    % Mostrar valores en cada celda
    h.CellLabelFormat = '%.1f%%';

    % Guardar figura
    set(gcf, 'Toolbar', 'none', 'Menu', 'none');
    saveas(gcf, fullfile(carpetaResultados, 'Mapa_Calor_Evolucion.png'));
    saveas(gcf, fullfile(carpetaResultados, 'Mapa_Calor_Evolucion.fig'));
    
    %% Exportar datos a Excel para análisis adicionales
    % Preparar tabla de datos
    categorias = {'Nubes', 'Agua', 'Suelo desnudo/Veg. marchita', 'Vegetación media', 'Vegetación densa'};
    datosTabla = [porcentajeNubes; porcentajeAgua; porcentajeMarchito; porcentajeVegMedia; porcentajeVegDensa];
    
    % Crear tabla
    T = array2table(datosTabla, 'RowNames', categorias, 'VariableNames', fechas);
    
    % Añadir índice de recuperación
    T_indices = array2table(indiceRecuperacion, 'VariableNames', fechas, 'RowNames', {'Índice de Recuperación'});
    
    % Guardar a Excel
    writetable(T, fullfile(carpetaResultados, 'Datos_Evolucion_Doñana.xlsx'), 'WriteRowNames', true, 'Sheet', 'Porcentajes');
    writetable(T_indices, fullfile(carpetaResultados, 'Datos_Evolucion_Doñana.xlsx'), 'WriteRowNames', true, 'Sheet', 'Índices');
    
    % Mostrar mensaje de finalización
    msgbox(sprintf(['Análisis completado. Los resultados se han guardado en la carpeta %s.\n\n' ...
                   'Se han generado 5 gráficos y un archivo Excel con los datos.'], ...
                   carpetaResultados), 'Análisis completado');
end