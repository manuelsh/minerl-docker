FROM nvidia/cuda:10.0-base-ubuntu18.04

# Install some basic utilities
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    sudo \
    git \
    bzip2 \
    libx11-6 \
    tmux \
    htop \
    gcc \
    xvfb \
    python-opengl\
    x11-xserver-utils\
 && rm -rf /var/lib/apt/lists/*

# Create a working directory
RUN mkdir /app
WORKDIR /app

# Create a non-root user and switch to it
RUN adduser --disabled-password --gecos '' --shell /bin/bash user \
 && chown -R user:user /app
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-user
USER user

# All users can use /home/user as their home directory
ENV HOME=/home/user
RUN chmod 777 /home/user

# Install Miniconda
RUN curl -so ~/miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-4.6.14-Linux-x86_64.sh \
 && chmod +x ~/miniconda.sh \
 && ~/miniconda.sh -b -p ~/miniconda \
 && rm ~/miniconda.sh
ENV PATH=/home/user/miniconda/bin:$PATH
ENV CONDA_AUTO_UPDATE_CONDA=false

# Create a Python 3.7 environment
RUN /home/user/miniconda/bin/conda install conda-build \
 && /home/user/miniconda/bin/conda create -y --name py37 python=3.7.3 \
 && /home/user/miniconda/bin/conda clean -ya
ENV CONDA_DEFAULT_ENV=py37
ENV CONDA_PREFIX=/home/user/miniconda/envs/$CONDA_DEFAULT_ENV
ENV PATH=$CONDA_PREFIX/bin:$PATH

# Install Minecraft needed libraries
RUN sudo apt-get update
RUN sudo apt-get install openjdk-8-jdk -y
RUN pip install --upgrade --user minerl

# PyTorch with CUDA 10 installation
RUN conda install -y -c pytorch \
    cuda100=1.0 \
    magma-cuda100=2.4.0 \
    "pytorch=1.1.0=py3.7_cuda10.0.130_cudnn7.5.1_0" \
    torchvision=0.3.0 \
 && conda clean -ya

# Install jupyter notebook
RUN pip install jupyter pandas matplotlib numpy scipy sklearn jupyterlab

# Create starting file
RUN echo "xhost + & jupyter notebook --allow-root --ip 0.0.0.0" > /app/xvfb.sh
RUN echo "xvfb-run -s \"-screen 0 1400x900x24\" /app/xvfb.sh" > /app/run.sh
RUN chmod ugo+x /app/xvfb.sh
RUN chmod ugo+x /app/run.sh

# Set the default command to jupyter
CMD ["sh", "/app/run.sh"]
