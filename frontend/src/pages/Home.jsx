import { useState } from 'react';
import FileUpload from '../components/FileUpload';
import ProgressBar from '../components/ProgressBar';
import ResultCard from '../components/ResultCard';
import QualitySelector from '../components/QualitySelector';
import { compressPDF, downloadPDF } from '../services/api';
import { Loader2 } from 'lucide-react';

const Home = () => {
  const [selectedFile, setSelectedFile] = useState(null);
  const [isCompressing, setIsCompressing] = useState(false);
  const [progress, setProgress] = useState(0);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);
  const [quality, setQuality] = useState('medium');

  const handleFileSelect = (file) => {
    setSelectedFile(file);
    setError(null);
    setResult(null);
  };

  const handleClearFile = () => {
    setSelectedFile(null);
    setError(null);
    setResult(null);
  };

  const handleCompress = async () => {
    if (!selectedFile) return;

    setIsCompressing(true);
    setError(null);
    setProgress(0);

    try {
      const data = await compressPDF(selectedFile, quality, (progressValue) => {
        setProgress(progressValue);
      });

      setResult(data);
      setSelectedFile(null);
    } catch (err) {
      setError(err.message || 'Erro ao comprimir o PDF');
      console.error('Compression error:', err);
    } finally {
      setIsCompressing(false);
      setProgress(0);
    }
  };

  const handleDownload = () => {
    if (result) {
      const downloadUrl = downloadPDF(result.filename);
      window.open(downloadUrl, '_blank');
    }
  };

  const handleReset = () => {
    setResult(null);
    setSelectedFile(null);
    setError(null);
  };

  return (
    <div className="flex-1 w-full">
      <div className="max-w-4xl mx-auto px-4 py-12">
        <div className="bg-white rounded-2xl shadow-xl p-8 md:p-12">
          {/* Title Section */}
          {!result && (
            <div className="text-center mb-8">
              <h2 className="text-3xl font-bold text-gray-800 mb-3">
                Comprima seu PDF
              </h2>
              <p className="text-gray-600">
                Reduza o tamanho do seu arquivo PDF mantendo a qualidade
              </p>
            </div>
          )}

          {/* Error Message */}
          {error && (
            <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded-xl animate-slide-up">
              <p className="text-red-700 text-center font-medium">{error}</p>
            </div>
          )}

          {/* Main Content */}
          {!result ? (
            <div className="space-y-6">
              <FileUpload
                onFileSelect={handleFileSelect}
                selectedFile={selectedFile}
                onClearFile={handleClearFile}
              />

              {selectedFile && !isCompressing && (
                <div className="space-y-6 animate-slide-up">
                  <QualitySelector
                    selectedQuality={quality}
                    onQualityChange={setQuality}
                  />

                  <button
                    onClick={handleCompress}
                    className="w-full bg-primary-600 hover:bg-primary-700 text-white font-semibold py-4 px-6 rounded-xl transition-all duration-300 transform hover:scale-105 shadow-lg hover:shadow-xl flex items-center justify-center space-x-2"
                  >
                    <Loader2 className="w-5 h-5" />
                    <span>Comprimir PDF</span>
                  </button>
                </div>
              )}

              {isCompressing && (
                <div className="mt-8">
                  <ProgressBar progress={progress} />
                </div>
              )}

              {/* Features Section */}
              <div className="mt-12 grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="text-center p-4">
                  <div className="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-3">
                    <span className="text-2xl">🚀</span>
                  </div>
                  <h3 className="font-semibold text-gray-800 mb-2">Rápido</h3>
                  <p className="text-sm text-gray-600">
                    Compressão instantânea de arquivos
                  </p>
                </div>

                <div className="text-center p-4">
                  <div className="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-3">
                    <span className="text-2xl">🔒</span>
                  </div>
                  <h3 className="font-semibold text-gray-800 mb-2">Seguro</h3>
                  <p className="text-sm text-gray-600">
                    Seus arquivos são processados com segurança
                  </p>
                </div>

                <div className="text-center p-4">
                  <div className="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center mx-auto mb-3">
                    <span className="text-2xl">✨</span>
                  </div>
                  <h3 className="font-semibold text-gray-800 mb-2">Qualidade</h3>
                  <p className="text-sm text-gray-600">
                    Mantém a qualidade do documento
                  </p>
                </div>
              </div>
            </div>
          ) : (
            <ResultCard
              result={result}
              onDownload={handleDownload}
              onReset={handleReset}
            />
          )}
        </div>
      </div>
    </div>
  );
};

export default Home;
