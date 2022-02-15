FROM smartnodefr/pythonligo:latest

RUN wget https://gitlab.com/ligolang/ligo/-/jobs/1816125591/artifacts/raw/ligo

RUN chmod +x ./ligo

RUN cp ./ligo /usr/local/bin

COPY . .

WORKDIR src/contract

RUN ligo compile contract farm/main.mligo > test/compiled/farm.tz

RUN ligo compile contract database/main.mligo > test/compiled/database.tz

WORKDIR test

ENTRYPOINT [ "pytest"]
