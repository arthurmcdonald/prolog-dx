% A simple toy database for testing and demoing
% Note: this is not real medical data

kb_meta(source, 'hand-written seed data (illustrative only)').
kb_meta(license, 'CC0-1.0').

disease(influenza,         'influenza').
disease(common_cold,       'common cold').
disease(strep_throat,      'strep throat').
disease(migraine,          'migraine').
disease(meningitis,        'meningitis').
disease(allergic_rhinitis, 'allergic rhinitis').
disease(pneumonia,         'pneumonia').

symptom(fever,             'fever').
symptom(cough,             'cough').
symptom(sore_throat,       'sore throat').
symptom(runny_nose,        'runny nose').
symptom(sneezing,          'sneezing').
symptom(headache,          'headache').
symptom(nausea,            'nausea').
symptom(stiff_neck,        'stiff neck').
symptom(light_sensitivity, 'light sensitivity').
symptom(fatigue,           'fatigue').
symptom(body_aches,        'body aches').
symptom(itchy_eyes,        'itchy eyes').
symptom(dyspnea,           'dyspnea').
symptom(chest_pain,        'chest pain').

presents(influenza, fever).
presents(influenza, cough).
presents(influenza, sore_throat).
presents(influenza, headache).
presents(influenza, fatigue).
presents(influenza, body_aches).
presents(influenza, runny_nose).

presents(common_cold, cough).
presents(common_cold, sore_throat).
presents(common_cold, runny_nose).
presents(common_cold, sneezing).
presents(common_cold, fatigue).

presents(strep_throat, fever).
presents(strep_throat, sore_throat).
presents(strep_throat, headache).
presents(strep_throat, nausea).

presents(migraine, headache).
presents(migraine, nausea).
presents(migraine, light_sensitivity).

presents(meningitis, fever).
presents(meningitis, headache).
presents(meningitis, stiff_neck).
presents(meningitis, nausea).
presents(meningitis, light_sensitivity).

presents(allergic_rhinitis, runny_nose).
presents(allergic_rhinitis, sneezing).
presents(allergic_rhinitis, itchy_eyes).
presents(allergic_rhinitis, fatigue).

presents(pneumonia, fever).
presents(pneumonia, cough).
presents(pneumonia, dyspnea).
presents(pneumonia, chest_pain).
presents(pneumonia, fatigue).
