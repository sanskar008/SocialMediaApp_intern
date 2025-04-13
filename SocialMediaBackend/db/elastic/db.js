require('dotenv').config();
const { Client } = require('@elastic/elasticsearch');

const host = process.env.ELASTIC_HOST || 'http://localhost:9200'; // HTTP host
let ElasticClientInstance;

class ElasticSearchDB {
  constructor() {
    this.client = new Client({
      node: host,
    });
  }

  async getClient() {
    if (!ElasticClientInstance) return this.connect();
    return ElasticClientInstance;
  }

  async connect() {
    if (ElasticClientInstance) return Promise.resolve(ElasticClientInstance); // Reuse connection

    ElasticClientInstance = new Client({
      node: host,
    });

    try {
      await ElasticClientInstance.ping();
      console.log('Connected to Elasticsearch');
      return ElasticClientInstance;
    } catch (err) {
      console.error('Error connecting to Elasticsearch:', err.message);
      throw err;
    }
  }

  async createIndex(indexName, mappings = {}) {
    try {
      const exists = await ElasticClientInstance.indices.exists({ index: indexName });
      if (!exists) {
        await ElasticClientInstance.indices.create({
          index: indexName,
          body: mappings,
        });
      }
    } catch (err) {
      console.error(`Error creating index ${indexName}:`, err.message);
      throw err;
    }
  }
}

module.exports = {
  ElasticSearchDB,
  instance: new ElasticSearchDB(),
};
