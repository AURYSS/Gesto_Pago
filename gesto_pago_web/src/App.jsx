import React, { useState } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import LoginView from './components/LoginView';
import TwoFactorModal from './components/TwoFactorModal';
import Navbar from './components/Navbar';
import CatalogoGrid from './components/CatalogoGrid';
import HistorialView from './components/HistorialView';

function AppContent() {
  const { isAuthenticated, step } = useAuth();
  const [activeTab, setActiveTab] = useState('catalogo');

  if (!isAuthenticated) {
    return (
      <>
        <LoginView />
        {step === '2fa' && <TwoFactorModal />}
      </>
    );
  }

  return (
    <div className="app-container">
      <Navbar activeTab={activeTab} setActiveTab={setActiveTab} />
      <main className="main-content">
        {activeTab === 'catalogo' && (
          <CatalogoGrid onPagoRealizado={() => setActiveTab('historial')} />
        )}
        {activeTab === 'historial' && <HistorialView />}
      </main>
    </div>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}
