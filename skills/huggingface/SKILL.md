---
name: huggingface
description: HuggingFace ecosystem expert — model hub, Transformers, Diffusers, Datasets, Inference API, Spaces, and PEFT/fine-tuning. Use when the user wants to load or deploy a HuggingFace model, write Transformers/Diffusers pipelines, fine-tune with LoRA/QLoRA, push to the Hub, or build a Gradio Space.
license: MIT
source: kariimc/my-skills
---

# HuggingFace

End-to-end patterns for working with the HuggingFace ecosystem: Hub, Transformers, Diffusers, Datasets, PEFT, and Inference API.

## When to Activate

- Loading or running models from the HuggingFace Hub
- Writing `pipeline()`, `AutoModel`, or `AutoTokenizer` code
- Using the Diffusers library for image/video/audio generation
- Fine-tuning with LoRA, QLoRA, or full fine-tuning via PEFT + TRL
- Working with `datasets` library for data loading/streaming
- Pushing models, datasets, or Spaces to the Hub
- Using the Inference API or Inference Endpoints

## Hub Basics

```python
from huggingface_hub import login, hf_hub_download, snapshot_download
login(token="hf_...")  # or set HF_TOKEN env var

# Download a single file
path = hf_hub_download(repo_id="meta-llama/Llama-3.2-1B", filename="config.json")

# Download full repo
local_dir = snapshot_download(repo_id="stabilityai/stable-diffusion-xl-base-1.0")
```

## Transformers Pipelines

```python
from transformers import pipeline

# Text generation
gen = pipeline("text-generation", model="meta-llama/Llama-3.2-1B-Instruct",
               device_map="auto", torch_dtype="auto")
out = gen("Hello, I am", max_new_tokens=100)

# Text classification, NER, summarization, translation all follow same pattern
clf = pipeline("text-classification", model="distilbert-base-uncased-finetuned-sst-2-english")
```

## AutoModel / AutoTokenizer

```python
from transformers import AutoTokenizer, AutoModelForCausalLM
import torch

model_id = "mistralai/Mistral-7B-Instruct-v0.3"
tokenizer = AutoTokenizer.from_pretrained(model_id)
model = AutoModelForCausalLM.from_pretrained(
    model_id,
    torch_dtype=torch.bfloat16,
    device_map="auto",          # spreads across available GPUs/CPU
    load_in_4bit=True,          # BitsAndBytes 4-bit quantization
)

messages = [{"role": "user", "content": "Explain attention in one sentence."}]
inputs = tokenizer.apply_chat_template(messages, return_tensors="pt").to(model.device)
out = model.generate(inputs, max_new_tokens=200)
print(tokenizer.decode(out[0], skip_special_tokens=True))
```

## Diffusers

```python
from diffusers import StableDiffusionXLPipeline, DPMSolverMultistepScheduler
import torch

pipe = StableDiffusionXLPipeline.from_pretrained(
    "stabilityai/stable-diffusion-xl-base-1.0",
    torch_dtype=torch.float16,
    use_safetensors=True,
).to("cuda")
pipe.scheduler = DPMSolverMultistepScheduler.from_config(pipe.scheduler.config)

image = pipe("A photorealistic cat astronaut", num_inference_steps=25).images[0]
image.save("output.png")
```

## Datasets

```python
from datasets import load_dataset, Dataset

# Load from Hub
ds = load_dataset("HuggingFaceFW/fineweb", split="train", streaming=True)
for sample in ds.take(5):
    print(sample["text"][:200])

# Create from local files
ds = Dataset.from_dict({"text": [...], "label": [...]})
ds.push_to_hub("your-username/my-dataset", private=True)
```

## Fine-Tuning with PEFT + TRL (LoRA/QLoRA)

```python
from transformers import AutoModelForCausalLM, BitsAndBytesConfig
from peft import LoraConfig, get_peft_model
from trl import SFTTrainer, SFTConfig
from datasets import load_dataset

bnb_config = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_compute_dtype="bfloat16")
model = AutoModelForCausalLM.from_pretrained("meta-llama/Llama-3.2-1B", quantization_config=bnb_config)

lora_config = LoraConfig(r=16, lora_alpha=32, target_modules="all-linear", lora_dropout=0.05)
model = get_peft_model(model, lora_config)

ds = load_dataset("your-dataset", split="train")
trainer = SFTTrainer(
    model=model,
    args=SFTConfig(output_dir="./output", num_train_epochs=3, per_device_train_batch_size=4),
    train_dataset=ds,
)
trainer.train()
trainer.model.push_to_hub("your-username/my-finetuned-model")
```

## Inference API

```python
from huggingface_hub import InferenceClient

client = InferenceClient(token="hf_...")

# Serverless (free tier, rate-limited)
out = client.text_generation("The quick brown fox", model="mistralai/Mistral-7B-v0.1", max_new_tokens=50)

# Dedicated Inference Endpoint
client = InferenceClient(base_url="https://your-endpoint.endpoints.huggingface.cloud", token="hf_...")
```

## Pushing to Hub

```python
from transformers import AutoModelForCausalLM, AutoTokenizer

model.push_to_hub("username/model-name", private=False)
tokenizer.push_to_hub("username/model-name")

# Or save locally first
model.save_pretrained("./my-model")
tokenizer.save_pretrained("./my-model")
```

## Gradio Spaces

```python
# app.py — deploy to HuggingFace Spaces (ZeroGPU or CPU)
import gradio as gr
from transformers import pipeline

pipe = pipeline("text-generation", model="gpt2")

def generate(prompt):
    return pipe(prompt, max_new_tokens=100)[0]["generated_text"]

gr.Interface(fn=generate, inputs="text", outputs="text").launch()
```

```yaml
# README.md (Space card)
---
title: My Demo
sdk: gradio
sdk_version: "4.44.0"
app_file: app.py
hardware: cpu-basic   # or t4-small, a10g-small, zero-gpu
---
```

## Key Gotchas

- `device_map="auto"` requires `accelerate` installed.
- BitsAndBytes quantization only works on CUDA; use `llama.cpp` or `mlx` for Apple Silicon.
- `apply_chat_template()` is model-specific — always use the tokenizer's template, don't hand-roll it.
- Safetensors (`.safetensors`) is preferred over pickle (`.bin`) for security.
- Set `HF_HOME` env var to redirect the model cache away from the default `~/.cache/huggingface/`.
- For streaming generation use `TextStreamer` or `TextIteratorStreamer` from `transformers`.
- Serverless Inference API has a 30s timeout; for long-running tasks use Inference Endpoints or local.
