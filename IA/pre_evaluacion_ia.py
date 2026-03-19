#!/usr/bin/env python3
"""
Servicio de IA para pre-evaluación médica de Yoltec.
Analiza respuestas de síntomas y sugiere diagnósticos preliminares.
"""

import sys
import json
import os
from typing import Dict, List, Tuple

# Cargar configuración de enfermedades
CONFIG_PATH = os.path.join(os.path.dirname(__file__), 'enfermedades_config.json')

with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
    CONFIG = json.load(f)

ENFERMEDADES = CONFIG['enfermedades']
PREGUNTAS = {p['id']: p for p in CONFIG['preguntas']}


def calcular_puntuacion(respuestas: Dict[str, str]) -> List[Dict]:
    """
    Calcula la puntuación de coincidencia para cada enfermedad.
    
    Args:
        respuestas: Diccionario con respuestas del usuario {pregunta_id: respuesta}
    
    Returns:
        Lista de enfermedades ordenadas por puntuación
    """
    resultados = []
    
    for enfermedad in ENFERMEDADES:
        puntuacion = 0
        sintomas_detectados = []
        peso_total = 0
        
        for sintoma in enfermedad['sintomas']:
            if sintoma in respuestas:
                respuesta = respuestas[sintoma]
                peso = PREGUNTAS.get(sintoma, {}).get('peso', 1)
                peso_total += peso
                
                # Asignar puntuación según la severidad de la respuesta
                if isinstance(respuesta, str):
                    if 'No' in respuesta or respuesta == '0':
                        pass  # No suma puntos
                    elif 'leve' in respuesta.lower() or 'disminuido' in respuesta.lower():
                        puntuacion += peso * 0.5
                        sintomas_detectados.append(f"{sintoma} (leve)")
                    elif 'moderado' in respuesta.lower() or 'frecuentemente' in respuesta.lower():
                        puntuacion += peso * 0.75
                        sintomas_detectados.append(f"{sintoma} (moderado)")
                    elif 'severo' in respuesta.lower() or 'intenso' in respuesta.lower() or 'constante' in respuesta.lower():
                        puntuacion += peso * 1.0
                        sintomas_detectados.append(f"{sintoma} (severo)")
                    elif 'alta' in respuesta.lower() or 'completamente' in respuesta.lower():
                        puntuacion += peso * 1.0
                        sintomas_detectados.append(f"{sintoma} (alta)")
                    else:
                        # Respuesta positiva genérica
                        puntuacion += peso * 0.75
                        sintomas_detectados.append(sintoma)
        
        # Calcular confianza como porcentaje de síntomas detectados
        if peso_total > 0:
            confianza = min(puntuacion / (peso_total * 0.6), 1.0)  # Normalizar a 60% de síntomas
        else:
            confianza = 0
        
        # Bonus por síntomas clave
        sintomas_clave_detectados = sum(1 for s in enfermedad['preguntas_clave'] 
                                       if s in respuestas and 'No' not in str(respuestas[s]))
        if sintomas_clave_detectados >= len(enfermedad['preguntas_clave']) * 0.7:
            confianza = min(confianza * 1.2, 1.0)  # Bonus del 20%
        
        if confianza > 0.15:  # Umbral mínimo para considerar
            resultados.append({
                'enfermedad': enfermedad['nombre'],
                'confianza': round(confianza, 2),
                'sintomas_detectados': sintomas_detectados,
                'sintomas_esperados': len(enfermedad['sintomas']),
                'sintomas_presentes': len(sintomas_detectados)
            })
    
    # Ordenar por confianza descendente
    resultados.sort(key=lambda x: x['confianza'], reverse=True)
    
    return resultados


def generar_diagnostico(respuestas: Dict[str, str]) -> Dict:
    """
    Genera un diagnóstico preliminar basado en las respuestas.
    
    Args:
        respuestas: Diccionario con respuestas del usuario
    
    Returns:
        Diccionario con el diagnóstico y recomendaciones
    """
    resultados = calcular_puntuacion(respuestas)
    
    if not resultados:
        return {
            'diagnostico_principal': 'Sin diagnóstico claro',
            'confianza': 0,
            'sintomas_detectados': [],
            'posibles_enfermedades': [],
            'recomendacion': 'Los síntomas no son concluyentes. Se recomienda consulta médica para evaluación más detallada.'
        }
    
    top_resultado = resultados[0]
    
    # Generar recomendación basada en la confianza
    confianza = top_resultado['confianza']
    if confianza >= 0.8:
        recomendacion = f"Alta probabilidad de {top_resultado['enfermedad']}. Se recomienda atención médica prioritaria."
    elif confianza >= 0.6:
        recomendacion = f"Probabilidad moderada de {top_resultado['enfermedad']}. Se recomienda consulta médica."
    elif confianza >= 0.4:
        recomendacion = f"Posible {top_resultado['enfermedad']}. Monitorear síntomas y considerar consulta médica."
    else:
        recomendacion = "Síntomas no concluyentes. Se recomienda consulta médica para evaluación más detallada."
    
    return {
        'diagnostico_principal': top_resultado['enfermedad'],
        'confianza': top_resultado['confianza'],
        'sintomas_detectados': top_resultado['sintomas_detectados'],
        'posibles_enfermedades': resultados[:3],  # Top 3
        'recomendacion': recomendacion
    }


def main():
    """Función principal que procesa entrada JSON desde stdin."""
    try:
        # Leer JSON de stdin
        input_data = sys.stdin.read()
        data = json.loads(input_data)
        
        respuestas = data.get('respuestas', {})
        
        if not respuestas:
            print(json.dumps({
                'error': 'No se proporcionaron respuestas',
                'success': False
            }))
            sys.exit(1)
        
        resultado = generar_diagnostico(respuestas)
        resultado['success'] = True
        
        print(json.dumps(resultado, ensure_ascii=False))
        
    except json.JSONDecodeError as e:
        print(json.dumps({
            'error': f'Error al parsear JSON: {str(e)}',
            'success': False
        }))
        sys.exit(1)
    except Exception as e:
        print(json.dumps({
            'error': f'Error inesperado: {str(e)}',
            'success': False
        }))
        sys.exit(1)


if __name__ == '__main__':
    main()
