# SocialMediaBE

This is a Node.js server that requires Elasticsearch, MongoDB, and Redis to run on their respective localhosts.

## Requirements

- Node.js
- Elasticsearch
- MongoDB
- Redis

## Installation

1. Clone the repository:
    ```bash
    git clone <repository-url>
    cd SocialMediaBE
    ```

2. Install the dependencies:
    ```bash
    npm install
    ```

3. Ensure that Elasticsearch, MongoDB, and Redis are running on their localhosts.

## Running the Server

Start the server with:
```bash
npm start
```

## Configuration

Make sure to configure your environment variables as needed. You can use a `.env` file to set up your configurations. An example `env` file can be found in the folder for reference.

## Dependencies

### Elasticsearch
Elasticsearch is a distributed, RESTful search and analytics engine capable of solving a growing number of use cases. It is used in this project to provide powerful search capabilities and to index data for quick retrieval.

- **Installation**: Follow the [official installation guide](https://www.elastic.co/guide/en/elasticsearch/reference/current/install-elasticsearch.html).
- **Running**: Start Elasticsearch with the command:
    ```bash
    docker run -d --name es01 -p 9200:9200 -p 9300:9300  -e "discovery.type=single-node"  -e "xpack.security.enabled=false"  -e "xpack.security.http.ssl.enabled=false"  docker.elastic.co/elasticsearch/elasticsearch:8.17.3
    ```


### MongoDB
MongoDB is a NoSQL database known for its flexibility and scalability. It stores data in JSON-like documents, making it easy to work with hierarchical data structures.

- **Installation**: Follow the [official installation guide](https://docs.mongodb.com/manual/installation/).
- **Running**: Start MongoDB with the command:
    ```bash
    docker run --name mongodb -p 27017:27017 -d mongodb/mongodb-community-server:latest
    ```

### Redis
Redis is an in-memory data structure store, used as a database, cache, and message broker. It supports various data structures such as strings, hashes, lists, sets, and more.

- **Installation**: Follow the [official installation guide](https://redis.io/download).
- **Running**: Start Redis with the command:
    ```bash
   docker run -d --name redis-stack -p 6379:6379 -p 8001:8001 redis/redis-stack:latest
    ```
