import * as multer from 'multer';
import bcrypt, { hash } from 'bcrypt';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';
import { v4 as uuidv4 } from 'uuid';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const path2PrivateKey = path.join(__dirname,"..","key","private.key");

const PRIVATE_KEY = fs.readFileSync(path2PrivateKey,"utf8");

const mimeTypes = {
    "image/png":"png",
    "image/jpeg":"jpg",
    "image/jpg":"jpg",
    "image/gif":"gif",
    "video/mp4":"mp4",
    "audio/mpeg":"mp3",
    "audio/wav":"wav",
    "application/pdf":"pdf",
    "application/vnd.ms-excel":"xls",
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":"xlsx"
};

const getBasePath = (reqPath) => {
    
    let basePath = "uploads/Others";
  
    if(reqPath === "/location-create" || reqPath === "/location-modify")
    {
        basePath = "uploads/locations";
    }
    else if(reqPath === "/location-detail-create" || reqPath === "/location-detail-modify")
    {
        basePath = "uploads/location-details";
    }

    return basePath;
}

const accessFilePath = (fileType, reqpath) => {
    let basePath = getBasePath(reqpath);

    let dest =
      mimeTypes[fileType] === "mp4"
        ? path.join(__dirname, "..", basePath, "video")
        : mimeTypes[fileType] === "pdf"
        ? path.join(__dirname, "..", basePath, "documents", "pdf")
        : mimeTypes[fileType] === "xls" || mimeTypes[fileType] === "xlsx"
        ? path.join(__dirname, "..", basePath, "documents", "excel")
        : mimeTypes[fileType] === "mp3" || mimeTypes[fileType] === "wav"
        ? path.join(__dirname, "..", basePath, "audio")
        : mimeTypes[fileType] === "gif"
        ? path.join(__dirname, "..", basePath, "gif")
        : path.join(__dirname, "..", basePath, "image");
  
    return dest;
};

const multerConfig = {
    storage: multer.diskStorage({
        destination: (req, file, callback) => {
        
            const fileType = file.mimetype;

            let dest = accessFilePath(fileType, req?.path);

            if (!fs.existsSync(dest)) {
                fs.mkdirSync(dest, { recursive: true });
            }

            callback(null, dest);
        },

        filename: (req, file, callback) => {
            const ext = mimeTypes[file.mimetype];
            callback(null, `${uuidv4()}.${ext}`);
          },

    }),

    fileFilter: (req, file, callback) => {
        const ext = mimeTypes[file.mimetype];

        ext === "png" ||
        ext === "jpg" ||
        ext === "gif" ||
        ext === "wav" ||
        ext === "mp3" ||
        ext === "wav" ||
        ext === "mp4" ||
        ext === "pdf" ||
        ext === "xls" ||
        ext === "xlsx"
            ? callback(null, true)
            : callback(null, false);
    },

}

export const accessBaseFilePath = (fileName, reqPath) => {
    let basename = getBasePath(reqPath);
    const fileType = fileName.split('.').pop();

    basename = fileType === "mp4"
        ? path.join(basename, "video")
        : fileType === "pdf"
        ? path.join(basename, "documents", "pdf")
        : fileType === "xls" || fileType === "xlsx"
        ? path.join(basename, "documents", "excel")
        : fileType === "mp3" || fileType === "wav"
        ? path.join(basename, "audio")
        : fileType === "gif"
        ? path.join(basename, "gif")
        : path.join(basename, "image");

        basename =  basename.concat('/').concat(fileName);
        
        if(!basename || !fs.existsSync(basename))
        {
            return null;
        }

    return  basename;
    // return  bcrypt.hashSync(basename, bcrypt.genSaltSync(10) || process.env.IMG_KEY);
}


export const deleteFiles = (files) => {

    const dest = files;

    if(!dest)
    {
        return false;
    }

    // const ext = filenamewithext.split('.')[1];
    // dest = accessFilePath(ext);

    // if(!dest){
    //     return false;
    // }

    // dest = dest + filenamewithext;

    if(!fs.existsSync(dest))
    {
        return false;
    }

    return fs.unlinkSync(dest,(err)=>{
        if(err)
        {
            console.error("Error in call to fs.unlink");

            return false;
        }
        else
        {
            console.log("Successfully deleted the file.");
        }
        return true;
    });
}



export const upload = multer.default(multerConfig);
