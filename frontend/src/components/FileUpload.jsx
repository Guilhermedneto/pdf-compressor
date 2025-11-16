import { useState, useRef } from 'react';
import { Upload, File, X } from 'lucide-react';

const FileUpload = ({ onFileSelect, selectedFile, onClearFile }) => {
  const [isDragging, setIsDragging] = useState(false);
  const fileInputRef = useRef(null);

  const handleDragEnter = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(true);
  };

  const handleDragLeave = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);
  };

  const handleDragOver = (e) => {
    e.preventDefault();
    e.stopPropagation();
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setIsDragging(false);

    const files = e.dataTransfer.files;
    if (files && files.length > 0) {
      const file = files[0];
      if (file.type === 'application/pdf') {
        onFileSelect(file);
      } else {
        alert('Por favor, selecione apenas arquivos PDF');
      }
    }
  };

  const handleFileInput = (e) => {
    const file = e.target.files[0];
    if (file) {
      onFileSelect(file);
    }
  };

  const handleClick = () => {
    fileInputRef.current?.click();
  };

  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  };

  return (
    <div className="w-full">
      <input
        ref={fileInputRef}
        type="file"
        accept="application/pdf"
        onChange={handleFileInput}
        className="hidden"
      />

      {!selectedFile ? (
        <div
          onClick={handleClick}
          onDragEnter={handleDragEnter}
          onDragOver={handleDragOver}
          onDragLeave={handleDragLeave}
          onDrop={handleDrop}
          className={`
            relative border-2 border-dashed rounded-2xl p-12 text-center cursor-pointer
            transition-all duration-300 ease-in-out
            ${isDragging
              ? 'border-primary-500 bg-primary-50 scale-105'
              : 'border-gray-300 hover:border-primary-400 hover:bg-gray-50'
            }
          `}
        >
          <div className="flex flex-col items-center space-y-4">
            <div className={`
              p-4 rounded-full transition-all duration-300
              ${isDragging ? 'bg-primary-100' : 'bg-gray-100'}
            `}>
              <Upload className={`
                w-12 h-12 transition-colors duration-300
                ${isDragging ? 'text-primary-600' : 'text-gray-400'}
              `} />
            </div>

            <div className="space-y-2">
              <p className="text-lg font-semibold text-gray-700">
                Arraste e solte seu PDF aqui
              </p>
              <p className="text-sm text-gray-500">
                ou clique para selecionar um arquivo
              </p>
            </div>

            <div className="mt-4 px-6 py-2 bg-primary-500 text-white rounded-lg hover:bg-primary-600 transition-colors">
              Selecionar arquivo
            </div>
          </div>
        </div>
      ) : (
        <div className="relative border-2 border-primary-500 rounded-2xl p-8 bg-primary-50 animate-slide-up">
          <button
            onClick={onClearFile}
            className="absolute top-4 right-4 p-2 rounded-full bg-white hover:bg-gray-100 transition-colors shadow-md"
          >
            <X className="w-5 h-5 text-gray-600" />
          </button>

          <div className="flex items-start space-x-4">
            <div className="p-3 bg-primary-100 rounded-lg">
              <File className="w-8 h-8 text-primary-600" />
            </div>

            <div className="flex-1">
              <h3 className="font-semibold text-gray-800 text-lg mb-1">
                {selectedFile.name}
              </h3>
              <p className="text-sm text-gray-600">
                Tamanho: {formatFileSize(selectedFile.size)}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default FileUpload;
