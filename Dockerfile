FROM smartnodefr/pythonligo:latest

COPY . .

RUN ligo compile contract contract/main/main.mligo -e main --michelson-format json > deploy/ressources/Farm.json

RUN ligo compile contract contract/main/farms.mligo -e main --michelson-format json > deploy/ressources/Farms.json

WORKDIR /contract

RUN ligo compile contract main/main.mligo -e main > test/Farm.tz

RUN ligo compile contract main/farms.mligo -e main > test/Farms.tz

WORKDIR /contract/test

ENTRYPOINT [ "pytest"]