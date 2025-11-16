const ProgressBar = ({ progress }) => {
  return (
    <div className="w-full animate-slide-up">
      <div className="flex justify-between items-center mb-2">
        <span className="text-sm font-medium text-gray-700">
          Comprimindo seu PDF...
        </span>
        <span className="text-sm font-semibold text-primary-600">
          {progress}%
        </span>
      </div>

      <div className="w-full h-3 bg-gray-200 rounded-full overflow-hidden shadow-inner">
        <div
          className="h-full bg-gradient-to-r from-primary-500 to-primary-600 rounded-full transition-all duration-300 ease-out relative overflow-hidden"
          style={{ width: `${progress}%` }}
        >
          <div className="absolute inset-0 bg-white opacity-20 animate-pulse-slow"></div>
        </div>
      </div>

      <p className="text-xs text-gray-500 mt-2 text-center">
        Por favor, aguarde enquanto processamos seu arquivo
      </p>
    </div>
  );
};

export default ProgressBar;
