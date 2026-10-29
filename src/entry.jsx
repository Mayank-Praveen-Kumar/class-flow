import React from 'react';
import {createRoot} from 'react-dom/client';
import {App} from './main.jsx';
import AuthGate from './AuthGate.jsx';
createRoot(document.getElementById('root')).render(<AuthGate><App/></AuthGate>);
