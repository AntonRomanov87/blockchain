# DApp "Casino Ethereum"
Основано на https://medium.com/@merunasgrincalaitis/the-ultimate-end-to-end-tutorial-to-create-and-deploy-a-fully-descentralized-dapp-in-ethereum-18f0cf6d7e0e

Чтобы попробовать, используйте ссылку (нужен Метамаск, соединение с тестнетом Görli и немного тестовых ETH):
https://gateway.ipfs.io/ipns/k51qzi5uqu5dlqk3qfjam1fgubh5l0ujtx2pb1a4y7e0oodqgevmkmb8bxf5b9
(когда и если моя IPFS нода запущена)

##Как собрать проект и задеплоить.

Установить Node.js
https://nodejs.org/

Установить Ganache и Truffle:
npm install -g ganache-cli
npm install -g truffle

Скачать код и перейти в папку casino-ethereum.

### Тестирование и деплой смарт-контрактов
Скомпилировать контракты используя truffle:
```bash
truffle compile
```

Задеплоить контракты в локальном тестнете ganache (запустить ganache-cli в отдельном терминале/окне):
```bash
ganache-cli -l 10000000
```

Деплой:
```bash
truffle migrate
```

Запуск тестов:
```bash
truffle test
```

### Задеплоить контракты в сети Görli ###
Скачать и установить Geth (если еще не установлен).
https://geth.ethereum.org/downloads/

Синхронизироваться с тестнетом Görli в лайт-режиме (подождать пока синхронизация не будет завершена ~15 мин)
```bash
geth --goerli --v5disc --syncmode light
```

Завершить выполнение geth и перезапустить с параметрами:
```bash
geth --goerli --v5disc --syncmode light --http --http.port 8547 --verbosity 2 --allow-insecure-unlock console
```

Откроется консоль geth. Проверить, есть ли уже аккаунты (в консоли geth):
```
eth.accounts
```

Проверить баланс аккаунта в ETH (в консоли geth):
```
web3.fromWei(eth.getBalance(eth.accounts[0]),"ether")
```

Если нет аккаунтов, то создать аккаунт (в консоли geth):
```
personal.newAccount()
```
При создании первого аккаунта будет запрошена фраза-пароль (passphrase). Ввести и запомнить.
Скопировать созданные номер аккаунта и получить ETH из фасетов Görli
https://goerlifaucet.com/
https://goerli-faucet.mudit.blog/

Разблокировать аккаунт (в консоли geth):
```
personal.unlockAccount(eth.accounts[0],"<passphrase>",1e9)
```

Проверить баланс аккаунта после получения ETH из фасетов (в консоли geth):
```
web3.fromWei(eth.getBalance(eth.accounts[0]),"ether")
```

Не закрывая geth, запущенный в отдельном терминале/окне, задеплоить контракты в Görli (аккаунт с достаточным количеством ETH должен быть в разблокированном состоянии):
```bash
truffle migrate --reset --network goerli
```

Записать номер контракта Казино, например 0x68afD32894AECb1A7c73616bcEDA91F78962838b
(отображается в секции "2_deploy_contract.js")


### Обновить код и собрать билд используя webpack
ABI для Casino.sol доступно в папке build/contracts после компиляции контрактов.
Обновить ABI и адрес задеплоенного контракта в файле src/js/index.js:
```js
const MyContract = web3.eth.contract(<contract ABI>);
this.state.ContractInstance = MyContract.at("<contract address>")
```

Собрать dist/build.js:
```bash
webpack
```

### Тестируем локально
Запустить простейший веб-сервер с корнем в папке dist:
```
http-server dist/
```
Перейти, не закрывая сервер, по адресу http://localhost:8080 для тестирования

### Деплой в IPFS
Скачать и установить (распаковать и переместить в подходящую папку) IPFS with command line
https://docs.ipfs.io/install/command-line/
Добавит путь к ipfs.exe в переменную окружения PATH.

Проверить, что ipfs доступен:
```bash
ipfs --version
```

Инициализировать хранилище IPFS (делается один раз, создается папка .ipfs в корне папки пользователя - не в папке проекта):
```bash
ipfs init
```

Запустить IPFS демон (должен быть запущен в отдельном терминале/окне):
```bash
ipfs daemon
```

Опубликовать папку ```dist/``` в IPFS:
```bash
ipfs add -r dist/
```

Пример вывода (при использование Windows Cmd вывод хешей будет обрезан => используйте Power Shell or Git Bash):
```bash
added QmPdYx7jN5UaMzvwNAmUWiGQ28ZJCsHkwf1mMtRVjcYwmp dist/build.js
added Qme3zqhXKouQaMpQ4aXHJ3gNMozfvVGX1wn9HtbEnFKukB dist/build.js.LICENSE.txt
added QmZXr4vfJK7GzNBMkeuN5RX7j2yz9EKZ1mmv5boojaJ8X8 dist/favicon.ico
added QmW1zu8pRP1Cb9yiRz5z2HqtYhmzZuGMyoopZKxvyGPuSG dist/index.html
added QmbF27fbYRFzTjAW4sECncQ6CZwmDDea25WmGDkqHuCUzA dist
 382.92 KiB / 382.92 KiB  100.00%

added QmWZyrPrajQ8yKH5LYann16JCywWYYcLefTHvPteyTvb7L dist/build.js
added Qme3zqhXKouQaMpQ4aXHJ3gNMozfvVGX1wn9HtbEnFKukB dist/build.js.LICENSE.txt
added QmZXr4vfJK7GzNBMkeuN5RX7j2yz9EKZ1mmv5boojaJ8X8 dist/favicon.ico
added QmW1zu8pRP1Cb9yiRz5z2HqtYhmzZuGMyoopZKxvyGPuSG dist/index.html
added QmYcQHwcTw8kXqDHk7oidMQjDjeJwDoSCgws3AuCQwNjYp dist
 382.92 KiB / 382.92 KiB  100.00%

```

Опубликовать в IPNS используя хеш папки ```dist/```:
```bash
ipfs name publish QmYcQHwcTw8kXqDHk7oidMQjDjeJwDoSCgws3AuCQwNjYp
```
Пример вывода команды:
```bash
Published to k51qzi5uqu5dlqk3qfjam1fgubh5l0ujtx2pb1a4y7e0oodqgevmkmb8bxf5b9: /ipfs/QmYcQHwcTw8kXqDHk7oidMQjDjeJwDoSCgws3AuCQwNjYp
```

#### Теперь DApp доступен через IPFS
###### IPFS адреса (изменяются каждый раз, как меняется папка или файл):
Публичный шлюз: 
https://gateway.ipfs.io/ipfs/QmYcQHwcTw8kXqDHk7oidMQjDjeJwDoSCgws3AuCQwNjYp

Локальный шлюз:
http://localhost:8080/ipfs/QmYcQHwcTw8kXqDHk7oidMQjDjeJwDoSCgws3AuCQwNjYp

###### IPNS адреса (постоянны несмотря на изменения папки или файлов)
Публичный шлюз:
https://gateway.ipfs.io/ipns/k51qzi5uqu5dlqk3qfjam1fgubh5l0ujtx2pb1a4y7e0oodqgevmkmb8bxf5b9

Локальный шлюз:
http://localhost:8080/ipns/k51qzi5uqu5dlqk3qfjam1fgubh5l0ujtx2pb1a4y7e0oodqgevmkmb8bxf5b9


