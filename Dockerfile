FROM smartnodefr/pythonligo:latest

COPY contract contract

WORKDIR /contract

RUN ligo compile contract main/main.mligo -e main > test/Farm.tz

RUN ligo compile contract main/farms.mligo -e main > test/Farms.tz

WORKDIR /contract/test

ENTRYPOINT [ "pytest"]