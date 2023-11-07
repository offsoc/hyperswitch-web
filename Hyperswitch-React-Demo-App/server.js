const fetch = require("node-fetch");
const express = require("express");
const app = express();
const { resolve } = require("path");

// Replace if using a different env file or config
const env = require("dotenv").config({ path: "./.env" });
app.use(express.static(process.env.STATIC_DIR));
app.get("/", (req, res) => {
  const path = resolve(process.env.STATIC_DIR + "/index.html");
  res.sendFile(path);
});

// replace the test api key with your hyperswitch api key
const hyper = require("@juspay-tech/hyperswitch-node")(
  process.env.HYPERSWITCH_SECRET_KEY
);

const SERVER_URL = process.env.HYPERSWITCH_SERVER_URL == "SERVER_URL" ? "" : process.env.HYPERSWITCH_SERVER_URL;

app.get("/config", (req, res) => {
  res.send({
    publishableKey: process.env.HYPERSWITCH_PUBLISHABLE_KEY,
  });
});

app.get("/server", (req, res) => {
  res.send({
    serverUrl: SERVER_URL,
  });
});

app.get("/create-payment-intent", async (req, res) => {
  try {
    var paymentIntent;
    const request = {
      currency: "USD",
      amount: 2999,
    }
    if (SERVER_URL) {
      const apiResponse = await fetch(`${process.env.HYPERSWITCH_SERVER_URL}/payments`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'api-key': process.env.HYPERSWITCH_SECRET_KEY,
        },
        body: JSON.stringify(request),
      });
      paymentIntent = await apiResponse.json();

      if (paymentIntent.error) {
        return res.status(400).send({
          error: paymentIntent.error,
        });
      }
    } else {
      paymentIntent = await hyper.paymentIntents.create(request);
    }

    // Send publishable key and PaymentIntent details to client
    res.send({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (err) {
    return res.status(400).send({
      error: {
        message: err.message,
      },
    });
  }
});

app.listen(5252, () =>
  console.log(`Node server listening at http://localhost:5252`)
);