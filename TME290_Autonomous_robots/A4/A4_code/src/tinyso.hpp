/*
 * MIT License
 *
 * Copyright (c) 2018 Ola Benderius
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#ifndef TINYSOA_HPP
#define TINYSOA_HPP

#include <algorithm>
#include <cmath>
#include <ctime>
#include <future>
#include <iostream>
#include <random>
#include <utility>
#include <vector>

namespace tinyso {

typedef std::vector<double> Fitnesses;
typedef std::vector<double> Individual;
typedef std::vector<Individual> Population;

enum class CrossoverMethod {
  Shuffle,
  Split
};

class GeneticAlgorithm {
  public:
    GeneticAlgorithm(std::function<double(Individual const &, uint32_t const)>,
        CrossoverMethod const, uint32_t const, uint32_t const, uint32_t const, 
        uint32_t const, float const, float const, float const);
    virtual ~GeneticAlgorithm();
    double GetBestFitness() const;
    Individual GetBestIndividual() const;
    int32_t GetGenerationIndex() const;
    void NextGeneration(uint32_t const);
    Population GetPopulation() const;
    Fitnesses GetFitnesses() const;
    void SetCrossoverIndividuals(
        std::function<std::pair<Individual, Individual>(Individual const &,
          Individual const &)>);
    void SetMutateIndividual(std::function<Individual(Individual const &)>);

  private:
    GeneticAlgorithm(GeneticAlgorithm const &);
    GeneticAlgorithm &operator=(GeneticAlgorithm const &);
    std::pair<Individual, Individual> CrossoverIndividuals(Individual const &,
        Individual const &);
    Fitnesses EvaluatePopulation(Population const &, uint32_t const);
    Population GeneratePopulation(uint32_t const);
    uint32_t GetRandomInteger(uint32_t, uint32_t);
    double GetRandomCreep();
    double GetRandomDouble();
    float GetRandomFloat();
    Individual MutateIndividual(Individual const &);
    Individual SelectTournament(Population const &, Fitnesses const &);

    std::default_random_engine m_generator;
    std::function<std::pair<Individual, Individual>(Individual const &,
        Individual const &)> m_crossover_individuals;
    std::function<double(Individual const &, uint32_t const)> 
      m_evaluate_individual;
    std::function<Individual(Individual const &)> m_mutate_individual;
    CrossoverMethod m_crossover_method;
    Fitnesses m_fitnesses;
    Individual m_best_individual;
    Population m_population;
    double m_best_fitness;
    float const m_prob_crossover;
    float const m_prob_mutation;
    float const m_prob_select_tournament;
    uint32_t m_generation_index;
    uint32_t const m_elite_size;
    uint32_t const m_population_size;
    uint32_t const m_tournament_size;
};

inline GeneticAlgorithm::GeneticAlgorithm(
    std::function<double(Individual const &, uint32_t const)> evaluate_individual,
    CrossoverMethod const crossover_method, uint32_t const individual_length, 
    uint32_t const elite_size, uint32_t const population_size, 
    uint32_t const tournament_size, float prob_crossover, float prob_mutation,
    float prob_select_tournament):
  m_generator(time(0)),
  m_crossover_individuals(nullptr),
  m_evaluate_individual(evaluate_individual),
  m_mutate_individual(nullptr),
  m_crossover_method(crossover_method),
  m_fitnesses(),
  m_best_individual(),
  m_population(),
  m_best_fitness(std::numeric_limits<double>::lowest()),
  m_prob_crossover(prob_crossover),
  m_prob_mutation(prob_mutation),
  m_prob_select_tournament(prob_select_tournament),
  m_generation_index(0),
  m_elite_size(elite_size),
  m_population_size(population_size),
  m_tournament_size(tournament_size)
{
  m_population = GeneratePopulation(individual_length);
}

inline GeneticAlgorithm::~GeneticAlgorithm()
{
}

inline std::pair<Individual, Individual> GeneticAlgorithm::CrossoverIndividuals(
    Individual const &individual_1, Individual const &individual_2)
{
  if (m_crossover_individuals != nullptr) {
    return m_crossover_individuals(individual_1, individual_2);
  }

  switch (m_crossover_method) {
    case CrossoverMethod::Shuffle:
      {
        uint32_t const individual_length = individual_1.size();

        Individual crossed_1(individual_length);
        Individual crossed_2(individual_length);

        for (uint32_t i = 0; i < individual_length; ++i) {
          float const r = GetRandomFloat();
          if (r < 0.5) {
            crossed_1[i] = individual_1[i];
            crossed_2[i] = individual_2[i];
          } else {
            crossed_1[i] = individual_2[i];
            crossed_2[i] = individual_1[i];
          }
        }

        std::pair<Individual, Individual> pair(crossed_1, crossed_2);
        return pair;
      }
    case CrossoverMethod::Split:
      {
        uint32_t const individual_length = individual_1.size();

        uint32_t split_pos = GetRandomInteger(1, individual_length - 1);

        Individual crossed_1(individual_length);
        Individual crossed_2(individual_length);

        for (uint32_t i = 0; i < individual_length; ++i) {
          if (i < split_pos) {
            crossed_1[i] = individual_1[i];
            crossed_2[i] = individual_2[i];
          } else {
            crossed_1[i] = individual_2[i];
            crossed_2[i] = individual_1[i];
          }
        }

        std::pair<Individual, Individual> pair(crossed_1, crossed_2);
        return pair;
      }
    default:
      {
        std::pair<Individual, Individual> emptyPair;
        return emptyPair;
      }
  }
}

inline Fitnesses GeneticAlgorithm::EvaluatePopulation(Population const &population,
    uint32_t const cores)
{
  Fitnesses fitnesses(m_population_size);
  std::mutex selection_mutex;
  std::mutex fitness_write_mutex;
  uint32_t evaluated = 0;

  auto worker{[this, &population, &fitnesses, &evaluated, &selection_mutex,
    &fitness_write_mutex]() {
    while (evaluated < m_population_size) {
      uint32_t index;
      {
        std::lock_guard<std::mutex> lock(selection_mutex);
        if (evaluated >= m_population_size) {
          break;
        }
        index = evaluated;
        evaluated++;
      }
      double fitness = m_evaluate_individual(population[index], index);
      {
        std::lock_guard<std::mutex> lock(fitness_write_mutex);
        fitnesses[index] = fitness;
      }
    }
  }};

  std::vector<std::thread> threads;
  for (uint32_t i{0}; i < cores; i++) {
    threads.push_back(std::thread(worker));
  }
  for (auto &t : threads) {
    t.join();
  }

  return fitnesses;
}

inline Population GeneticAlgorithm::GeneratePopulation(uint32_t individual_length)
{
  Population population(m_population_size);
  for (uint32_t i = 0; i < m_population_size; ++i) {
    Individual individual(individual_length);
    for (uint32_t j = 0; j < individual_length; ++j) {      
      individual[j] = GetRandomDouble();
    }
    population[i] = individual;
  }
  return population;
}

inline double GeneticAlgorithm::GetBestFitness() const
{
  return m_best_fitness;
}

inline Individual GeneticAlgorithm::GetBestIndividual() const
{
  return m_best_individual;
}

inline int32_t GeneticAlgorithm::GetGenerationIndex() const
{
  return m_generation_index;
}

inline Population GeneticAlgorithm::GetPopulation() const
{
  return m_population;
}

inline Fitnesses GeneticAlgorithm::GetFitnesses() const
{
  return m_fitnesses;
}

inline uint32_t GeneticAlgorithm::GetRandomInteger(uint32_t min, uint32_t max)
{
  std::uniform_int_distribution<uint32_t> int_distribution(min, max);
  return int_distribution(m_generator);
}

inline double GeneticAlgorithm::GetRandomCreep()
{
  std::normal_distribution<double> normal_distribution(0.0, 0.1);
  return normal_distribution(m_generator);
}

inline double GeneticAlgorithm::GetRandomDouble()
{
  std::uniform_real_distribution<double> uniform_distribution(0.0, 1.0);
  return uniform_distribution(m_generator);
}

inline float GeneticAlgorithm::GetRandomFloat()
{
  std::uniform_real_distribution<float> uniform_distribution(0.0, 1.0);
  return uniform_distribution(m_generator);
}

inline Individual GeneticAlgorithm::MutateIndividual(
    Individual const &individual)
{
  if (m_mutate_individual != nullptr) {
    return m_mutate_individual(individual);
  }

  float const r = GetRandomFloat();
  if (r < m_prob_mutation) {
    uint32_t const individual_length = individual.size();
    Individual individual_mutated(individual_length);
    for (uint32_t i = 0; i < individual_length; ++i) {
      double m = GetRandomCreep();

      double x = individual[i] + m;
      if (x < 0.0) {
        x = -x;
      }
      if (x > 1.0) {
        x = 2.0 - x;
      }

      individual_mutated[i] = x;
    }
    return individual_mutated;
  } else {
    return individual;
  }
}

inline void GeneticAlgorithm::NextGeneration(uint32_t cores)
{
  m_generation_index++;

  m_fitnesses = EvaluatePopulation(m_population, cores);

  uint32_t i_highest{0};
  double highest_fitness{std::numeric_limits<double>::lowest()};
  for (uint32_t i{0}; i < m_fitnesses.size(); i++) {
    if (!std::isnan(m_fitnesses[i]) && m_fitnesses[i] > highest_fitness) {
      i_highest = i;
      highest_fitness = m_fitnesses[i];
    }
  }

  if (highest_fitness > m_best_fitness) {
    m_best_fitness = highest_fitness;
    m_best_individual = m_population[i_highest];
  }

  Population population_new(m_population_size);

  for (uint32_t i{0}; i < m_elite_size; i++) {
    population_new[i] = m_best_individual;
  }

  for (uint32_t i{m_elite_size}; i < m_population_size; i = i + 2) {
    Individual individual_selected_1 = SelectTournament(m_population,
        m_fitnesses);
    Individual individual_selected_2 = SelectTournament(m_population,
        m_fitnesses);

    std::pair<Individual, Individual> individual_pair = CrossoverIndividuals(
        individual_selected_1, individual_selected_2);

    Individual individual_mutated_1 = MutateIndividual(individual_pair.first);
    population_new[i] = individual_mutated_1;

    if (i + 1 < m_population_size) {
      Individual individual_mutated_2 = MutateIndividual(
          individual_pair.second);
      population_new[i + 1] = individual_mutated_2;
    }
  }

  m_population = population_new;
}

inline Individual GeneticAlgorithm::SelectTournament(Population const &population,
    Fitnesses const &fitnesses)
{
  uint32_t const population_size = population.size();

  uint32_t index_best = GetRandomInteger(0, population_size - 1);
  double fitness_best = fitnesses[index_best];

  for (uint32_t i = 0; i < m_tournament_size - 1; ++i) {
    uint32_t const index = GetRandomInteger(0, population_size - 1);
    double const fitness = fitnesses[index];
    if (fitness > fitness_best) {
      index_best = index;
      fitness_best = fitness;
    }
  }

  return population[index_best];
}

void GeneticAlgorithm::SetCrossoverIndividuals(std::function<std::pair<
    Individual, Individual>(Individual const &, Individual const &)> 
    crossover_individuals)
{
  m_crossover_individuals = crossover_individuals;
}

void GeneticAlgorithm::SetMutateIndividual(
    std::function<Individual(Individual const &)> mutate_individual)
{
  m_mutate_individual = mutate_individual;
}

}

#endif
