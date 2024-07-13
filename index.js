import express from "express";
import bodyParser from "body-parser";
import cookieParser from "cookie-parser";
import { cors } from "./config/corsOption.js";
import { requestLimiter } from "./config/requestLimited.js";
import { errorHandle } from "./middleware/errorHandle.js";
import path from "path";
import { fileURLToPath } from "url";

import district from "./routes/district/district.router.js";
import dormantal from "./routes/dormantal/dormantal.router.js";
import house from "./routes/house/house.router.js";
import land from "./routes/land/land.router.js";
import provnice from "./routes/province/province.router.js";
import village from "./routes/village/village.router.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
app.use(cors);
app.use(express.static(path.join(__dirname,'./houseimage')))
app.use(bodyParser.json());
app.use(cookieParser());
app.use(requestLimiter);

app.use("/api/district", district);
app.use("/api/dormantal", dormantal);
app.use("/api/house", house);
app.use("/api/land", land);
app.use("/api/provnice", provnice);
app.use("/api/village", village);

app.get("/", (req, res) => {
  res.send("Hello, World!");
});

app.use(errorHandle);

const APPPORT = Number(process.env.APPPORT);

app.listen(APPPORT, () => {
  console.log(`App is running on port ${APPPORT}`);
});
