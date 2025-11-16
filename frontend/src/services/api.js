import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'multipart/form-data',
  },
});

export const compressPDF = async (file, quality = 'medium', onUploadProgress) => {
  const formData = new FormData();
  formData.append('file', file);

  try {
    const response = await api.post('/api/compress', formData, {
      params: {
        quality: quality
      },
      onUploadProgress: (progressEvent) => {
        if (onUploadProgress) {
          const percentCompleted = Math.round(
            (progressEvent.loaded * 100) / progressEvent.total
          );
          onUploadProgress(percentCompleted);
        }
      },
    });

    return response.data;
  } catch (error) {
    if (error.response) {
      throw new Error(error.response.data.detail || 'Erro ao comprimir PDF');
    } else if (error.request) {
      throw new Error('Não foi possível conectar ao servidor');
    } else {
      throw new Error('Erro ao processar a solicitação');
    }
  }
};

export const downloadPDF = (filename) => {
  return `${API_BASE_URL}/api/download/${filename}`;
};

export default api;
