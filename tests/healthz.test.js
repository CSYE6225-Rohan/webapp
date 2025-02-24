const request = require("supertest");
const { sequelize, testDbConnection } = require("../config/db");
const app = require("../app");
const HealthzCheck = require("../model/model");

// database
beforeAll(async () => {
  await sequelize.authenticate();
  await sequelize.sync();
});

describe("Health Check Controller", () => {
  let transaction;

  beforeEach(async () => {
    transaction = await sequelize.transaction();
  });dtsdtss

  afterEach(async () => {
    await transaction.rollback();
  });

  it("It should respond with a 200 OK status and log a health check record if the database connection is valid.", async () => {

    const response = await request(app).get("/healthz");
    expect(response.status).toBe(200);
    const records = await HealthzCheck.findAll();
    expect(records.length).toBeGreaterThan(0); 
    expect(records[0].datetime).toBeDefined(); 
  });

  it("It should respond with a 503 Service Unavailable status if the database connection is unavailable.", async () => {
    jest.spyOn(HealthzCheck, "create").mockImplementation(() => {
      throw new Error("Database Connection Failed");
    });
    const response = await request(app).get("/healthz");
    expect(response.status).toBe(503);
    HealthzCheck.create.mockRestore();
  });


  it("It should respond with a 503 Service Unavailable status if an error occurs while inserting the health check record.", async () => {
    jest
      .spyOn(HealthzCheck, "create")
      .mockRejectedValue(new Error("Insertion error"));

    const response = await request(app).get("/healthz");

    expect(response.status).toBe(503);
    expect(HealthzCheck.create).toHaveBeenCalled();
  });

  it("It should respond with a 405 Method Not Allowed status for unsupported HTTP methods.", async () => {
    const response = await request(app).post("/healthz"); // Assuming /healthz route only accepts GET

    expect(response.status).toBe(405);
  });

  it("should return 400 Bad Request if the request has arguments", async () => {
    const response = await request(app)
      .get("/healthz")
      .send({ invalidField: "test" });

    expect(response.status).toBe(400);
  });
});

afterAll(async () => {
  await sequelize.close();
});
