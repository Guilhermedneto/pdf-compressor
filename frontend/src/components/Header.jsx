import { FileDown } from 'lucide-react';

const Header = () => {
  return (
    <header className="w-full bg-gradient-to-r from-primary-600 to-primary-700 shadow-lg">
      <div className="max-w-7xl mx-auto px-4 py-6">
        <div className="flex items-center justify-center space-x-3">
          <div className="p-2 bg-white rounded-lg">
            <FileDown className="w-8 h-8 text-primary-600" />
          </div>
          <div>
            <h1 className="text-3xl font-bold text-white">PDF Compressor</h1>
            <p className="text-primary-100 text-sm">Comprima seus PDFs de forma rápida e fácil</p>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;
