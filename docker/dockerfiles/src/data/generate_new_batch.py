import sys
import yaml
sys.path.append('src')
from data.data_generator import FraudDataGenerator
from datetime import datetime

def main(config_path='params.yaml'):

    # Load config
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)

    generator = FraudDataGenerator()
    batch_id = datetime.now().strftime("%Y%m%d_%H%M%S")
    data = generator.generate_batch(config['data']['batch_size'], config['data']['fraud_rate'])
    filepath = generator.save_batch(data, batch_id)
    print(f"New batch generated: {filepath}")

if __name__ == "__main__":
    main()