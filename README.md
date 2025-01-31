# MindScribe: Decentralized Reflection Journal

MindScribe is a privacy-focused decentralized platform built on the Stacks blockchain that allows users to store and share their personal reflections securely. Using smart contracts, it provides a unique way to maintain personal thoughts with customizable privacy settings and timed reveals.

## Features

- **Secure Storage**: Store personal reflections on the blockchain with encryption
- **Privacy Controls**: Choose between private and public reflections
- **Anonymous Sharing**: Option to share reflections anonymously with delayed reveal
- **Categorization**: Add up to 10 categories per reflection for easy organization
- **Timed Reveals**: Set specific times for when reflections become visible
- **Shared Pool**: Anonymous reflections enter a shared pool with randomized reveal times
- **Category Indexing**: Browse public reflections by categories

## Smart Contract Functions

### Core Functions

1. `add-reflection`
   - Add a new reflection with customizable privacy settings
   - Parameters: text, reveal-time, is-hidden, is-unnamed, categories
   - Returns: reflection-id

2. `read-reflection`
   - Read a specific reflection if you have permission
   - Parameters: reflection-id, author
   - Returns: reflection content and metadata

3. `update-visibility`
   - Update the privacy settings of your reflection
   - Parameters: reflection-id, is-hidden, is-unnamed
   - Returns: success status

### Utility Functions

1. `check-shared-reflection-status`
   - Check if an anonymous reflection has been revealed
   - Parameters: reflection-id
   - Returns: reveal status

2. `get-reflection-count`
   - Get the total number of reflections for a user
   - Parameters: author
   - Returns: reflection count

3. `get-public-reflections-by-category`
   - Browse public reflections by category
   - Parameters: category
   - Returns: list of reflection IDs and authors

4. `add-category-to-index`
   - Add a reflection to a category index
   - Parameters: reflection-id, category
   - Returns: success status

## Privacy Features

### Privacy Levels

1. **Public**: Visible to everyone immediately
2. **Timed**: Becomes visible after a specified block height
3. **Hidden**: Only visible to the author
4. **Unnamed**: Author remains anonymous until reveal time

### Anonymous Sharing Mechanism

- Anonymous reflections are placed in a shared pool
- Reveal times are randomized (minimum 12 hours + random time up to 24 hours)
- Once revealed, reflections become permanently visible
- Authors can't force early reveals

## Technical Specifications

- Maximum reflection length: 2048 characters
- Maximum categories per reflection: 10
- Maximum category length: 32 characters
- Maximum reflections per category index: 50

## Error Codes

- `err-unauthorized (u100)`: User not authorized for action
- `err-invalid-reflection (u101)`: Invalid reflection content
- `err-invalid-date (u102)`: Invalid reveal time
- `err-reflection-not-found (u103)`: Reflection doesn't exist
- `err-category-full (u104)`: Category index is full
- `err-invalid-category (u105)`: Invalid category format
- `err-invalid-author (u106)`: Invalid author principal
- `err-not-in-shared-pool (u107)`: Reflection not in shared pool
- `err-already-revealed (u108)`: Reflection already revealed

## Development Setup

1. Install Clarinet and its dependencies
2. Clone the repository
3. Run tests using Clarinet test suite
4. Deploy using Clarinet console or deployment scripts

## Security Considerations

- All reflections are stored on-chain
- Privacy is enforced through smart contract logic
- Users should be cautious with sensitive information
- Consider block times when setting reveal times

## Contributing

We welcome contributions to MindScribe! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description
4. Ensure all tests pass
