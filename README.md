# Simulador de Alocação de Instâncias na Nuvem

Este repositório contém um simulador desenvolvido em R para avaliar estratégias de alocação de instâncias na nuvem. O objetivo é comparar custos entre diferentes abordagens de compra, considerando instâncias sob demanda e instâncias reservadas, com a possibilidade de utilizar predição. O simulador emprega uma heurística para tomar decisões de compra, avaliando o custo-benefício de reservas com base nas projeções de demanda e no histórico de compras.
## Requisitos

Para executar o simulador, é necessário ter as seguintes bibliotecas instaladas no R:

```r
install.packages("tidyverse")
install.packages("tsibble")
```

## Formato do Arquivo de Entrada

O simulador recebe um arquivo CSV contendo a demanda de instâncias ao longo do tempo. O arquivo deve conter duas colunas:

- `start_date`: Data e hora de início do período.
- `num_instances`: Número de instâncias demandadas nesse período.

Exemplo de entrada:

```
start_date,num_instances
2024-01-01 00:00:00,10
2024-01-01 01:00:00,12
2024-01-01 02:00:00,8
```

