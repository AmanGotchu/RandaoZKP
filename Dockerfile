FROM node:16-buster@sha256:b35e76ba744a975b9a5428b6c3cde1a1cf0be53b246e1e9a4874f87034222b5a

# Set up basic system utils
RUN apt update && apt upgrade && apt install curl python3
RUN apt install build-essential libgmp-dev libsodium-dev nasm nlohmann-json3-dev

# Set up rust
RUN curl https://sh.rustup.rs -sSf | \
    sh -s -- --default-toolchain nightly -y
ENV PATH=/root/.cargo/bin:$PATH
RUN rustup update

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
RUN pip install pipenv
RUN apt-get update && apt-get install -y --no-install-recommends gcc

WORKDIR /src/python-proof
COPY ./python-proof ./
RUN pipenv shell
RUN pipenv install

# Set up rest of the repo
WORKDIR /src
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .

EXPOSE 8080

CMD ["bash"]
