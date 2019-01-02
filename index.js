const decompress = require('decompress');
const decompressUnzip = require('decompress-unzip');
const csvParser = require("csvtojson");
const PQueue = require('p-queue');
const path = require("path");
const fs = require("fs");
const { Pool, Client } = require('pg');
const args = require('args');

args
    .option('port', 'The port of postgresql', 5432)
    .option('host', 'host Postgresql', 'localhost')
    .option('database', 'database Postgresql', 'postgres')
    .option('password', 'password Postgresql', '')
    .option('user', 'user Postgresql', 'postgres')
    .option('schema', 'schema Postgresql', 'public')
    .option('input', 'path of GTFS (zip)')
    .option('init', 'drop & create table')

// const input = args.sub
// console.log(input);
// return;

let result = (async function () {
    const flags = args.parse(process.argv)

    if (!flags.input) {
        console.log('pas de input')
        return;
    }

    if (!fs.existsSync(flags.input)) {
        console.log(`le fichier ${flags.input} n'existe pas`);
        return;
    }

    const pool = new Pool({
        user: flags.user,
        host: flags.host,
        database: flags.database,
        password: flags.password,
        port: flags.port,
    })

    const schema = flags.schema;
    let client = await pool.connect();
    if (flags.init) {
        let createtable = fs.readFileSync(path.join(__dirname, 'createtable.sql'), 'utf8').replace(/{!schema!}/g, schema)
        console.log(`Create tables in the schema ${flags.schema} `)
        await client.query(createtable)
    }

    const queue = new PQueue({ concurrency: 2000 });
    let tables = ['agency', 'trips', 'calendar', 'calendar_dates', 'stops', 'stop_times', 'directions', 'fare_attributes', 'fare_rules', 'feed_info', 'frequencies', 'payment_methods', 'pickup_dropoff_types', 'routes', 'route_types', 'shapes', 'transfers', 'transfer_types'];
    // tables = tables.filter(el => el !=='trips' )
    let unziped = await decompress('./GTFS/SEM-GTFS.zip', { plugins: [decompressUnzip()] })

    await client.query('BEGIN')

    for (let i = 0; i < unziped.length; i++) {
        const extname = path.extname(unziped[i].path);
        const basename = path.basename(unziped[i].path).replace(extname, '')
        if (extname === '.txt' && tables.indexOf(basename) != -1) {
            console.log(basename);
            let data = await csvParser({ noheader: true, output: "csv" }).fromString(unziped[i].data.toString());
            let header = data.splice(0, 1)[0]
            const paramsValues = header.map((e, ind) => `$${ind + 1}`)
            const sql = `INSERT INTO ${schema}.${basename} (${header.join(',')}) VALUES (${paramsValues})`;
            for (const d of data) {
                queue.add(() => client.query(sql, d))
                    .then((res) => {


                    })
                    .catch(err => {
                        console.log(err);
                        console.log(sql)
                    });
            }
        }
    }

    queue.onIdle().then(e => {
        console.log('Done :)')
        client.query('COMMIT;').then(ev => {
            client.release()
            pool.end();
        }

        )
    }
    )

})();
