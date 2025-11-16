import { Settings } from 'lucide-react';

const QualitySelector = ({ selectedQuality, onQualityChange }) => {
  const qualityOptions = [
    {
      value: 'low',
      label: 'Baixa',
      description: 'Máxima compressão (ideal para visualização)',
      icon: '🗜️'
    },
    {
      value: 'medium',
      label: 'Média',
      description: 'Balanceada (recomendado)',
      icon: '⚖️'
    },
    {
      value: 'high',
      label: 'Alta',
      description: 'Alta qualidade (ideal para impressão)',
      icon: '🎯'
    },
    {
      value: 'maximum',
      label: 'Máxima',
      description: 'Qualidade máxima (arquivo)',
      icon: '💎'
    }
  ];

  return (
    <div className="w-full">
      <div className="flex items-center space-x-2 mb-4">
        <Settings className="w-5 h-5 text-gray-700" />
        <h3 className="text-lg font-semibold text-gray-800">
          Qualidade de Compressão
        </h3>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {qualityOptions.map((option) => (
          <button
            key={option.value}
            onClick={() => onQualityChange(option.value)}
            className={`
              relative p-4 rounded-xl border-2 transition-all duration-300
              hover:shadow-lg transform hover:scale-105
              ${selectedQuality === option.value
                ? 'border-primary-500 bg-primary-50 shadow-md'
                : 'border-gray-200 bg-white hover:border-primary-300'
              }
            `}
          >
            <div className="text-center space-y-2">
              <div className="text-3xl">{option.icon}</div>
              <div>
                <p className={`font-semibold ${
                  selectedQuality === option.value ? 'text-primary-700' : 'text-gray-800'
                }`}>
                  {option.label}
                </p>
                <p className="text-xs text-gray-600 mt-1">
                  {option.description}
                </p>
              </div>
            </div>

            {selectedQuality === option.value && (
              <div className="absolute top-2 right-2">
                <div className="w-6 h-6 bg-primary-500 rounded-full flex items-center justify-center">
                  <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                </div>
              </div>
            )}
          </button>
        ))}
      </div>

      <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
        <p className="text-sm text-blue-800">
          <span className="font-semibold">Dica:</span> Para a maioria dos casos, recomendamos a qualidade{' '}
          <span className="font-bold">Média</span>, que oferece um bom equilíbrio entre tamanho e qualidade.
        </p>
      </div>
    </div>
  );
};

export default QualitySelector;
