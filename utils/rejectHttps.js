import http from 'http';

export const Agent = new http.Agent({
    rejectUnauthorized: false,
})