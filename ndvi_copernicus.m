%% Script para visualizar NDVI con un color ramp personalizado (estilo Copernicus)
% Se usa el siguiente ramp de pares [valor, color_hex]:
%   [-0.5, 0x0c0c0c],
%   [-0.2, 0xbfbfbf],
%   [-0.1, 0xdbdbdb],
%   [0, 0xeaeaea],
%   [0.025, 0xfff9cc],
%   [0.05, 0xede8b5],
%   [0.075, 0xddd89b],
%   [0.1, 0xccc682],
%   [0.125, 0xbcb76b],
%   [0.15, 0xafc160],
%   [0.175, 0xa3cc59],
%   [0.2, 0x91bf51],
%   [0.25, 0x7fb247],
%   [0.3, 0x70a33f],
%   [0.35, 0x609635],
%   [0.4, 0x4f892d],
%   [0.45, 0x3f7c23],
%   [0.5, 0x306d1c],
%   [0.55, 0x216011],
%   [0.6, 0x0f540a],
%   [1, 0x004400]
%
% El script interpola este ramp a un colormap de 256 colores y luego lo aplica
% a la visualización del NDVI (se asume que NDVI tiene rango [-0.5, 1]). 

%% 1. Definir el color ramp
ramp_values = [-0.5, -0.2, -0.1, 0, 0.025, 0.05, 0.075, 0.1, 0.125, 0.15, ...
    0.175, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 1];

% Los valores hexadecimales correspondientes, en forma de vector columna
hexColors = [...
    0x0c0c0c;...
    0xbfbfbf;...
    0xdbdbdb;...
    0xeaeaea;...
    0xfff9cc;...
    0xede8b5;...
    0xddd89b;...
    0xccc682;...
    0xbcb76b;...
    0xafc160;...
    0xa3cc59;...
    0x91bf51;...
    0x7fb247;...
    0x70a33f;...
    0x609635;...
    0x4f892d;...
    0x3f7c23;...
    0x306d1c;...
    0x216011;...
    0x0f540a;...
    0x004400];

% Función para convertir un valor hexadecimal a vector [r,g,b] normalizado [0,1]
hex2rgb = @(hexVal) [bitshift(hexVal, -16), bitand(bitshift(hexVal, -8), 255), bitand(hexVal, 255)]/255;

% Convertir cada valor hexadecimal a RGB
ramp_rgb = zeros(length(hexColors), 3);
for k = 1:length(hexColors)
    ramp_rgb(k,:) = hex2rgb(hexColors(k));
end

%% 2. Interpolar el colormap a 256 colores
N = 256;
xq = linspace(-0.5, 1, N); % rango en NDVI esperado
r_interp = interp1(ramp_values, ramp_rgb(:,1), xq, 'linear', 'extrap');
g_interp = interp1(ramp_values, ramp_rgb(:,2), xq, 'linear', 'extrap');
b_interp = interp1(ramp_values, ramp_rgb(:,3), xq, 'linear', 'extrap');
myColormap = [r_interp(:), g_interp(:), b_interp(:)];

%% 3. (Ejemplo) Cargar o calcular NDVI
% Aquí deberías colocar tu cálculo real. Para el ejemplo, genero NDVI sintético:
[x,y] = meshgrid(linspace(-0.5, 1, 500), linspace(-0.5, 1, 400));
NDVI = sin(2*pi*x).*cos(2*pi*y); % NDVI de ejemplo (puede tener valores fuera del rango)

% Forzar el rango a [-0.5, 1] (para visualización)
NDVI(NDVI < -0.5) = -0.5;
NDVI(NDVI > 1) = 1;

%% 4. Visualizar NDVI con el colormap personalizado
figure('Name', 'NDVI con Color Ramp personalizado');
imagesc(NDVI);
colormap(myColormap);
colorbar;
caxis([-0.5 1]);
title('NDVI - Visualización con Color Ramp Copernicus');