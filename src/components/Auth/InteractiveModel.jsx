import React, { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import { Float } from '@react-three/drei';
import * as THREE from 'three';

/**
 * InteractiveModel Component - Smart Paint Can
 * A procedural 3D model of a paint can that reacts to focus events.
 */
const InteractiveModel = ({ isFocused, focusField }) => {
    const groupRef = useRef();
    const lidRef = useRef();
    const canRef = useRef();

    const isPassword = focusField === 'password';

    useFrame((state) => {
        if (!groupRef.current) return;

        // 1. Mouse Parallax (Smooth transition)
        const targetX = (state.mouse.x * 0.4);
        const targetY = (state.mouse.y * 0.4);
        groupRef.current.rotation.x = THREE.MathUtils.lerp(groupRef.current.rotation.x, targetY, 0.1);
        groupRef.current.rotation.y = THREE.MathUtils.lerp(groupRef.current.rotation.y, targetX, 0.1);

        // 2. Password Animation (Lid Interaction)
        if (lidRef.current) {
            // If password is focused, close the lid (move down and rotate slightly)
            const targetLidY = (isPassword && isFocused) ? 0.75 : 1.2;
            const targetLidRotation = (isPassword && isFocused) ? 0 : -Math.PI / 8;

            lidRef.current.position.y = THREE.MathUtils.lerp(lidRef.current.position.y, targetLidY, 0.15);
            lidRef.current.rotation.x = THREE.MathUtils.lerp(lidRef.current.rotation.x, targetLidRotation, 0.15);
        }

        // 3. Scale & General Emphasis (Medium size for balanced UI)
        const baseScale = 0.45;
        const targetScale = isFocused ? baseScale * 1.2 : baseScale;
        groupRef.current.scale.setScalar(THREE.MathUtils.lerp(groupRef.current.scale.x, targetScale, 0.1));
    });

    return (
        <Float speed={1.5} rotationIntensity={0.5} floatIntensity={0.4}>
            <group ref={groupRef} scale={0.45} position={[0, 0, 0]}>

                {/* Paint Can Body */}
                <mesh ref={canRef} castShadow receiveShadow>
                    <cylinderGeometry args={[0.8, 0.8, 1.5, 32]} />
                    <meshStandardMaterial
                        color="#ffffff"
                        metalness={0.7}
                        roughness={0.2}
                        envMapIntensity={1}
                    />
                </mesh>

                {/* Paint Can Label (Brand Placeholder) */}
                <mesh position={[0, 0, 0.01]}>
                    <cylinderGeometry args={[0.81, 0.81, 0.8, 32, 1, true, 0, Math.PI * 1]} />
                    <meshStandardMaterial
                        color={isPassword && isFocused ? "#f59e0b" : "#3b82f6"}
                        roughness={0.3}
                    />
                </mesh>

                {/* Interactive Lid */}
                <group ref={lidRef} position={[0, 1.2, 0]}>
                    <mesh castShadow>
                        <cylinderGeometry args={[0.85, 0.85, 0.1, 32]} />
                        <meshStandardMaterial
                            color="#e5e7eb"
                            metalness={0.8}
                            roughness={0.1}
                        />
                    </mesh>
                    {/* Lid Handle/Ring */}
                    <mesh position={[0, 0.1, 0]}>
                        <torusGeometry args={[0.15, 0.03, 16, 32]} />
                        <meshStandardMaterial color="#9ca3af" metalness={1} />
                    </mesh>
                </group>

                {/* Bottom Rim */}
                <mesh position={[0, -0.75, 0]}>
                    <cylinderGeometry args={[0.82, 0.82, 0.05, 32]} />
                    <meshStandardMaterial color="#d1d5db" metalness={0.8} />
                </mesh>

            </group>
        </Float>
    );
};

export default InteractiveModel;
