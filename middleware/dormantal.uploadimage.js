import multer from 'multer';
  
const storage = multer.diskStorage({
 
  destination: function (req, file, cb) {
    // Ensure the directory path is correct and accessible
 
    cb(null, './dormantalimage');
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'itcw-' + uniqueSuffix + '-' + file.originalname);  // filenamek
  }
});
 
export const uploadimage = multer({ storage: storage }).single('file');