import React, { Suspense, useState, useEffect } from 'react';
import { Canvas } from '@react-three/fiber';
import { OrbitControls, PerspectiveCamera, Environment, ContactShadows } from '@react-three/drei';
import InteractiveModel from './InteractiveModel';

/**
 * WebGL Detection Helper
 */
const isWebGLAvailable = () => {
    try {
        const canvas = document.createElement('canvas');
        return !!(window.WebGLRenderingContext && (canvas.getContext('webgl') || canvas.getContext('experimental-webgl')));
    } catch (e) {
        return false;
    }
};

/**
 * AuthScene Component
 * Renders the 3D background/side scene for Auth pages with a graceful fallback.
 */
const AuthScene = ({ isFocused, focusField }) => {
    const [webglSupported, setWebglSupported] = useState(true);

    useEffect(() => {
        if (!isWebGLAvailable()) {
            setWebglSupported(false);
        }
    }, []);

    if (!webglSupported) {
        return (
            <div className="auth-3d-fallback" style={{
                width: '100%',
                height: '100%',
                background: 'linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
            }}>
                <div style={{ textAlign: 'center', color: '#6c757d', padding: '20px' }}>
                    <div style={{ fontSize: '48px', marginBottom: '10px' }}>✨</div>
                    <p>نحن نبني مستقبلاً مبهراً...</p>
                </div>
            </div>
        );
    }

    return (
        <div className="auth-3d-container" style={{ width: '100%', height: '100%', minHeight: '400px' }}>
            <Canvas shadows dpr={[1, 2]} onError={() => setWebglSupported(false)}>
                <PerspectiveCamera makeDefault position={[0, 0, 5]} fov={50} />

                <ambientLight intensity={0.5} />
                <spotLight position={[10, 10, 10]} angle={0.15} penumbra={1} intensity={1} castShadow />
                <pointLight position={[-10, -10, -10]} intensity={0.5} />

                <Suspense fallback={null}>
                    <InteractiveModel isFocused={isFocused} focusField={focusField} />
                    <Environment preset="city" />
                    <ContactShadows
                        position={[0, -1.5, 0]}
                        opacity={0.4}
                        scale={10}
                        blur={2.5}
                        far={4}
                    />
                </Suspense>

                <OrbitControls
                    enableZoom={false}
                    enablePan={false}
                    minPolarAngle={Math.PI / 2.5}
                    maxPolarAngle={Math.PI / 1.5}
                />
            </Canvas>
        </div>
    );
};

export default AuthScene;
