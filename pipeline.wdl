version 1.0

workflow DiffBind {
  input {
    # Sample sheet as CSV
    File csv
    Array[File]? files
    # String contrast
    # String? label = "factor"
    # String? flag

    # Width around summit (Default = 200 bp)
    Int? summits = 200

    String dockerImage = "quay.io/kdong2395/diffbind:master"
    Int? cpus = 8
    Int? memory = 32
  }

  if (!defined(files)) {
    call getFiles {
      input:
        csv = csv,
        dockerImage = dockerImage
    }
    
    call diffBind {
      input:
        csv = csv,
        files = getFiles.files,
        summits = summits,
        # contrast = contrast,
        # label = label,
        # flag = flag,
        dockerImage = dockerImage,
        cpus = getFiles.cpus,
        memory = getFiles.memory
    }
  }

  if (defined(files)) {
    call diffBind as diffBindJSON {
      input:
        csv = csv,
        files = files,
        summits = summits,
        # contrast = contrast,
        # label = label,
        # flag = flag,
        dockerImage = dockerImage,
        cpus = cpus,
        memory = memory
    }
  }

  output {
    # File outTSV = select_first([diffBind.outTSV, diffBindJSON.outTSV])
    # File outPDf = select_first([diffBind.outPDF, diffBindJSON.outPDF])
    File outRDS = select_first([diffBind.outRDS, diffBindJSON.outRDS])
  }
}

task getFiles {
  input {
    File csv
    String dockerImage
  }

  command <<<
    Rscript /getPaths.r '~{csv}'
  >>>

  runtime {
    maxRetries: 0
    docker: dockerImage
    disks: 'local-disk 4 HDD'
    memory: '2G'
    cpu: 1
  }

  output {
    Array[String] files = read_lines("files.txt")
    Int cpus = read_int('core.txt')
    Int memory = read_int('mem.txt')
  }
}

task diffBind {
  input {
    File csv
    Array[File]? files
    Int? summits
    # String contrast
    # String? label
    # String? flag
    String dockerImage
    Int? cpus
    Int? memory
  }

  command <<<
    echo "Input csv location:" '~{csv}'
    ls -lh /cromwell_root/broad-epi-aggregated-alns
    ls -lh /cromwell_root/broad-epi-segmentations
    Rscript /diffBind.r '~{csv}' ~{summits}
  >>>

  runtime {
    maxRetries: 0
    docker: dockerImage
    disks: 'local-disk 250 HDD'
    memory: memory + 'G'
    cpu: cpus
  }

  output {
    # File outTSV = 'deseq_results.tsv'
    # File outPDF = 'output.pdf'
    File outRDS = 'counted.rds'
  }
}