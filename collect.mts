import * as fs from 'node:fs'
import * as process from 'node:process'
import * as child_process from 'node:child_process'
import * as path from 'node:path'
import * as util from 'node:util'


let dir_path = './resources/pdf_dataset/pdfbox'

let files = fs.readdirSync(dir_path)

const exec = util.promisify(child_process.exec);

let parse_pdf = async (file: string): Promise<string | undefined> => {
    try {
        let pdf_file_path = path.join(dir_path, file)
        let command = `moon run main ${pdf_file_path}`
        await exec(command)
    } catch (error) {
        return file
    }
}


let tasks = []

for (let file of files) {
    tasks.push(parse_pdf(file))
}

Promise.all(tasks).then((results) => {
    let failed = results.filter((result) => result !== undefined)
    console.log("[")
    for (let file of failed) {
        console.log(`"${file}",`)
    }
    console.log("]")
})