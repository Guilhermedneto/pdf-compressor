import { Download, CheckCircle, FileText, TrendingDown } from 'lucide-react';

const ResultCard = ({ result, onDownload, onReset }) => {
  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
  };

  return (
    <div className="w-full space-y-6 animate-slide-up">
      {/* Success Header */}
      <div className="flex items-center justify-center space-x-3 text-green-600">
        <CheckCircle className="w-8 h-8" />
        <h2 className="text-2xl font-bold">PDF Comprimido com Sucesso!</h2>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Original Size */}
        <div className="bg-gradient-to-br from-blue-50 to-blue-100 rounded-xl p-6 border border-blue-200">
          <div className="flex items-center space-x-3 mb-2">
            <FileText className="w-5 h-5 text-blue-600" />
            <p className="text-sm font-medium text-blue-900">Tamanho Original</p>
          </div>
          <p className="text-2xl font-bold text-blue-700">
            {formatFileSize(result.original_size)}
          </p>
        </div>

        {/* Compressed Size */}
        <div className="bg-gradient-to-br from-green-50 to-green-100 rounded-xl p-6 border border-green-200">
          <div className="flex items-center space-x-3 mb-2">
            <TrendingDown className="w-5 h-5 text-green-600" />
            <p className="text-sm font-medium text-green-900">Tamanho Comprimido</p>
          </div>
          <p className="text-2xl font-bold text-green-700">
            {formatFileSize(result.compressed_size)}
          </p>
        </div>

        {/* Compression Ratio */}
        <div className="bg-gradient-to-br from-purple-50 to-purple-100 rounded-xl p-6 border border-purple-200">
          <div className="flex items-center space-x-3 mb-2">
            <CheckCircle className="w-5 h-5 text-purple-600" />
            <p className="text-sm font-medium text-purple-900">Redução</p>
          </div>
          <p className="text-2xl font-bold text-purple-700">
            {result.compression_ratio}%
          </p>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex flex-col sm:flex-row gap-4">
        <button
          onClick={onDownload}
          className="flex-1 flex items-center justify-center space-x-2 bg-primary-600 hover:bg-primary-700 text-white font-semibold py-4 px-6 rounded-xl transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-xl"
        >
          <Download className="w-5 h-5" />
          <span>Baixar PDF Comprimido</span>
        </button>

        <button
          onClick={onReset}
          className="flex-1 bg-gray-200 hover:bg-gray-300 text-gray-700 font-semibold py-4 px-6 rounded-xl transition-all duration-300"
        >
          Comprimir Outro Arquivo
        </button>
      </div>

      {/* File Info */}
      <div className="bg-gray-50 rounded-xl p-4 border border-gray-200">
        <p className="text-sm text-gray-600 text-center">
          <span className="font-semibold">Arquivo:</span> {result.filename}
        </p>
      </div>
    </div>
  );
};

export default ResultCard;
