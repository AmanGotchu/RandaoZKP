FROM node:16-buster@sha256:b35e76ba744a975b9a5428b6c3cde1a1cf0be53b246e1e9a4874f87034222b5a

# Set up basic system utils
RUN apt update && apt upgrade && apt install curl
RUN apt install build-essential libgmp-dev libsodium-dev nasm nlohmann-json3-dev vim

# Set up rust
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- --default-toolchain nightly -y
ENV PATH=/root/.cargo/bin:$PATH
RUN rustup update

# Set up python3.10
RUN apt update -y && apt upgrade -y && apt-get install -y wget build-essential libreadline-gplv2-dev libncursesw5-dev  libssl-dev  libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev
RUN set -xe apt-get update && apt-get install -y --no-install-recommends gcc python3-pip

WORKDIR /usr/src
RUN wget https://www.python.org/ftp/python/3.10.6/Python-3.10.6.tgz && tar xzf Python-3.10.6.tgz
WORKDIR /usr/src/Python-3.10.6
RUN ./configure --enable-optimizations && make altinstall

# Set up circom
WORKDIR /circom
RUN git clone https://github.com/iden3/circom.git .
RUN cargo build --release
RUN cargo install --path circom

# Set up circom-pairing
WORKDIR /src/circom-pairing
COPY ./circom-pairing/package.json ./circom-pairing/yarn.lock ./
RUN yarn install

# Set up python/pipenv
WORKDIR /src/python-proof
COPY ./python-proof ./
RUN python3.10 -m pip install -r requirements.txt

# Set up rest of the repo
WORKDIR /src
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .

RUN npm i -g snarkjs@0.5.0

RUN mkdir build

EXPOSE 8080

CMD ["bash"]
