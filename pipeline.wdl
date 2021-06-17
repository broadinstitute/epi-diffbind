version 1.0

workflow DiffBind {
  input {
    # Sample sheet as CSV
    File csv
    Array[File] files

    # Width around summit (Default = 200 bp)
    Int summits = 200

    # String dockerImage
  }

  call diffBind {
    input:
      csv = csv,
      files = files,
      summits = summits
      # dockerImage = dockerImage,
  }

  output {
    File outTSV = diffBind.outTSV
    File outPDf = diffBind.outPDF
  }
}

task diffBind {
  input {
    File csv
    Array[File] files
    Int summits = 200
    # String dockerImage
  }

  command <<<
    echo "Input csv location:" '~{csv}'
    Rscript /diffBind.r '~{csv}' ~{summits}
  >>>

  runtime {
    maxRetries: 0
  #   docker: dockerImage
  #   disks: 'local-disk 250G HDD'
  #   memory: '4G'
  #   cpu: 1
  }

  output {
    File outTSV = 'deseq_results.tsv'
    File outPDF = 'output.pdf'
  }
}
