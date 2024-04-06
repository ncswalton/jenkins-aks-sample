const express = require('express');
const mongodb = require('mongodb');

const app = express();
const client = new mongodb.MongoClient('mongodb://localhost:27017');

app.use(express.json());

app.post('/data', async (req, res) => {
  await client.connect();
  const db = client.db('mydatabase');
  const collection = db.collection('mycollection');
  await collection.insertOne(req.body);
  res.status(200).send('Data stored successfully');
});

app.listen(3000, () => console.log('Listening on port 3000'));
