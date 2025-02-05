# Parâmetros do Simulador

A função principal `run_simulation` recebe os seguintes parâmetros:

- `demands`: Data frame contendo a demanda de instâncias.
- `window`: Janela de previsão em horas.
- `ondemand_price`: Preço por hora de uma instância sob demanda.
- `upfront_cost`: Custo inicial de uma instância reservada.
- `hourly_cost_res`: Custo por hora de uma instância reservada.
- `reserve_duration`: Duração da reserva de uma instância em horas.
- `start`: Índice de início da simulação.
- `end`: Índice de término da simulação.
- `prediction_list`: Vetor com previsões para a simulação.
- `short_future`: Janela de tempo para decisão sobre compra de reserva.

## Execução

Para executar a simulação, utilize o seguinte código em R:

```r
library(tidyverse)
library(tsibble)

# Carregar dados de entrada
demands <- read_csv("caminho/do/arquivo.csv")

# Definir parâmetros
window <- 24
ondemand_price <- 0.10
upfront_cost <- 500
hourly_cost_res <- 0.05
reserve_duration <- 8760
start <- 1
end <- nrow(demands)
prediction_list <- rep(10, end * 2)  # Exemplo de previsão
short_future <- 48

# Executar simulação
resultado <- run_simulation(demands, window, ondemand_price, upfront_cost, hourly_cost_res, reserve_duration, start, end, prediction_list, short_future)

# Visualizar resultados
head(resultado)
```

## Saída do Simulador

O simulador retorna um data frame com as seguintes colunas:

- `start_date`: Data e hora do período.
- `num_instances`: Número de instâncias demandadas.
- `reserves`: Número de instâncias alocadas por meio de reservas.
- `ondemand`: Número de instâncias adquiridas sob demanda.
- `cost`: Custo acumulado ao longo do tempo.

Exemplo de saída:

```
start_date,num_instances,reserves,ondemand,cost
2024-01-01 00:00:00,10,5,5,50
2024-01-01 01:00:00,12,6,6,102
2024-01-01 02:00:00,8,5,3,135
```