-- Fix V100: column indices were off — first_name got last_name values, city got elo values.
-- Remove bad seed rows and re-insert correctly.

DELETE FROM ratings WHERE user_id IN (SELECT id FROM users WHERE email LIKE '%@kin.dev');
DELETE FROM users WHERE email LIKE '%@kin.dev';

DO $$
DECLARE
  pass TEXT := '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LzTFONlAWnm';
  players TEXT[][] := ARRAY[
    ARRAY['arun.kumar@kin.dev',      'Arun',      'Kumar',     'India',   'Chennai',           '1620', '12'],
    ARRAY['priya.sharma@kin.dev',    'Priya',     'Sharma',    'India',   'Mumbai',            '1580', '8'],
    ARRAY['rahul.verma@kin.dev',     'Rahul',     'Verma',     'India',   'Delhi',             '1750', '28'],
    ARRAY['sneha.patel@kin.dev',     'Sneha',     'Patel',     'India',   'Ahmedabad',         '1490', '5'],
    ARRAY['vikram.nair@kin.dev',     'Vikram',    'Nair',      'India',   'Bangalore',         '1810', '52'],
    ARRAY['deepa.menon@kin.dev',     'Deepa',     'Menon',     'India',   'Chennai',           '1670', '18'],
    ARRAY['kiran.rao@kin.dev',       'Kiran',     'Rao',       'India',   'Hyderabad',         '1540', '11'],
    ARRAY['anita.bose@kin.dev',      'Anita',     'Bose',      'India',   'Kolkata',           '1700', '33'],
    ARRAY['sanjay.gupta@kin.dev',    'Sanjay',    'Gupta',     'India',   'Mumbai',            '1380', '3'],
    ARRAY['meera.iyer@kin.dev',      'Meera',     'Iyer',      'India',   'Bangalore',         '1860', '61'],
    ARRAY['arjun.singh@kin.dev',     'Arjun',     'Singh',     'India',   'Delhi',             '1920', '47'],
    ARRAY['lakshmi.das@kin.dev',     'Lakshmi',   'Das',       'India',   'Chennai',           '1450', '7'],
    ARRAY['rohit.joshi@kin.dev',     'Rohit',     'Joshi',     'India',   'Pune',              '1600', '14'],
    ARRAY['kavya.reddy@kin.dev',     'Kavya',     'Reddy',     'India',   'Hyderabad',         '1730', '25'],
    ARRAY['nitin.shah@kin.dev',      'Nitin',     'Shah',      'India',   'Ahmedabad',         '1510', '9'],
    ARRAY['pooja.pillai@kin.dev',    'Pooja',     'Pillai',    'India',   'Kochi',             '1650', '20'],
    ARRAY['suresh.kumar@kin.dev',    'Suresh',    'Kumar',     'India',   'Bangalore',         '1780', '38'],
    ARRAY['divya.krishna@kin.dev',   'Divya',     'Krishna',   'India',   'Chennai',           '1420', '4'],
    ARRAY['manoj.tiwari@kin.dev',    'Manoj',     'Tiwari',    'India',   'Mumbai',            '1560', '13'],
    ARRAY['nalini.saxena@kin.dev',   'Nalini',    'Saxena',    'India',   'Delhi',             '1840', '55'],
    ARRAY['carlos.garcia@kin.dev',   'Carlos',    'Garcia',    'Spain',   'Madrid',            '1900', '44'],
    ARRAY['maria.lopez@kin.dev',     'Maria',     'Lopez',     'Spain',   'Barcelona',         '1760', '29'],
    ARRAY['juan.martinez@kin.dev',   'Juan',      'Martinez',  'Spain',   'Valencia',          '1630', '16'],
    ARRAY['elena.ruiz@kin.dev',      'Elena',     'Ruiz',      'Spain',   'Seville',           '1480', '6'],
    ARRAY['pablo.sanchez@kin.dev',   'Pablo',     'Sanchez',   'Spain',   'Madrid',            '1970', '70'],
    ARRAY['ana.fernandez@kin.dev',   'Ana',       'Fernandez', 'Spain',   'Barcelona',         '1690', '22'],
    ARRAY['luis.torres@kin.dev',     'Luis',      'Torres',    'Spain',   'Bilbao',            '1550', '10'],
    ARRAY['sofia.gomez@kin.dev',     'Sofia',     'Gomez',     'Spain',   'Madrid',            '1820', '48'],
    ARRAY['diego.morales@kin.dev',   'Diego',     'Morales',   'Spain',   'Malaga',            '1400', '2'],
    ARRAY['isabel.navarro@kin.dev',  'Isabel',    'Navarro',   'Spain',   'Zaragoza',          '1720', '26'],
    ARRAY['james.smith@kin.dev',     'James',     'Smith',     'UK',      'London',            '1590', '15'],
    ARRAY['emma.jones@kin.dev',      'Emma',      'Jones',     'UK',      'Manchester',        '1660', '19'],
    ARRAY['oliver.brown@kin.dev',    'Oliver',    'Brown',     'UK',      'London',            '1880', '58'],
    ARRAY['sophie.wilson@kin.dev',   'Sophie',    'Wilson',    'UK',      'Edinburgh',         '1470', '5'],
    ARRAY['harry.taylor@kin.dev',    'Harry',     'Taylor',    'UK',      'Birmingham',        '1740', '30'],
    ARRAY['charlotte.davies@kin.dev','Charlotte', 'Davies',    'UK',      'London',            '1530', '11'],
    ARRAY['george.evans@kin.dev',    'George',    'Evans',     'UK',      'Cardiff',           '1610', '17'],
    ARRAY['lily.thomas@kin.dev',     'Lily',      'Thomas',    'UK',      'London',            '1800', '42'],
    ARRAY['jack.roberts@kin.dev',    'Jack',      'Roberts',   'UK',      'Leeds',             '1360', '1'],
    ARRAY['isabella.white@kin.dev',  'Isabella',  'White',     'UK',      'London',            '1950', '65'],
    ARRAY['lucas.silva@kin.dev',     'Lucas',     'Silva',     'Brazil',  'Sao Paulo',         '1830', '50'],
    ARRAY['camila.santos@kin.dev',   'Camila',    'Santos',    'Brazil',  'Rio',               '1570', '12'],
    ARRAY['gabriel.lima@kin.dev',    'Gabriel',   'Lima',      'Brazil',  'Brasilia',          '1710', '24'],
    ARRAY['valentina.costa@kin.dev', 'Valentina', 'Costa',     'Brazil',  'Curitiba',          '1440', '4'],
    ARRAY['enzo.oliveira@kin.dev',   'Enzo',      'Oliveira',  'Brazil',  'Sao Paulo',         '1990', '73'],
    ARRAY['julia.rodrigues@kin.dev', 'Julia',     'Rodrigues', 'Brazil',  'Porto Alegre',      '1680', '21'],
    ARRAY['mateus.alves@kin.dev',    'Mateus',    'Alves',     'Brazil',  'Belo Horizonte',    '1520', '8'],
    ARRAY['beatriz.gomes@kin.dev',   'Beatriz',   'Gomes',     'Brazil',  'Fortaleza',         '1790', '36'],
    ARRAY['pedro.ferreira@kin.dev',  'Pedro',     'Ferreira',  'Brazil',  'Recife',            '1350', '0'],
    ARRAY['laura.barbosa@kin.dev',   'Laura',     'Barbosa',   'Brazil',  'Sao Paulo',         '1870', '60']
  ];
  r TEXT[];
  uid UUID;
  elo INT;
  matches INT;
BEGIN
  FOREACH r SLICE 1 IN ARRAY players LOOP
    uid := gen_random_uuid();
    elo := r[6]::INT;
    matches := r[7]::INT;

    INSERT INTO users (id, email, password_hash, first_name, last_name, country, city, plays_tournaments)
    VALUES (uid, r[1], pass, r[2], r[3], r[4], r[5], false);

    INSERT INTO ratings (user_id, elo, level, matches_confirmed, is_provisional, updated_at)
    VALUES (
      uid,
      elo,
      LEAST(GREATEST(ROUND(((elo - 1000) / 142.8)::NUMERIC, 2), 0), 7),
      matches,
      matches < 10,
      now()
    );
  END LOOP;
END $$;
