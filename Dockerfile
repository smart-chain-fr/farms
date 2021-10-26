FROM smartnodefr/pythonligo:latest

COPY . .

RUN ligo compile contract contract/main/main.mligo -e main --michelson-format json > deploy/ressources/Farm.json

WORKDIR /contract

RUN ligo compile contract main/main.mligo -e main > test/Farm.tz

WORKDIR /contract/test

ENTRYPOINT [ "pytest"]